

# This code is defining a Terraform configuration to create and configure various AWS resources.

resource "random_integer" "tag" {
  min = 1
  max = 50000
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.dns_support
  enable_dns_hostnames = var.dns_hostnames
  tags = local.vpc_tags
}

resource "aws_subnet" "subnet" {
  count      = var.my_count      # number of subnets to be created
  vpc_id     = aws_vpc.my_vpc.id # ID of the VPC where the subnet will be created.
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  # The availability zone where the subnet will be created. 
  # The subnets are evenly distributed across the available zones 1a, 1b. 1c.
  availability_zone = (count.index < 3 ?
    element(data.aws_availability_zones.my_az.names, count.index) :
    count.index < 6 ? element(data.aws_availability_zones.my_az.names, count.index - 3) :
  element(data.aws_availability_zones.my_az.names, count.index - 6))
  # Indicates whether instances launched in this subnet should be assigned a public IP address or not.
  # tfsec:ignore:aws-ec2-no-public-ip-subnet                    # DIRECTING tfsec to ignore the allocation of public ip to these subnets.
  map_public_ip_on_launch = count.index < 3 ? true : false
  tags = {
    Name = (count.index < 3
      ? "public_subnet_${count.index + 1}_${random_integer.tag.id}"
      : count.index < 6
      ? "private_subnet_${count.index - 2}_${random_integer.tag.id}"
    : "DataBase_subnet_${count.index - 5}_${random_integer.tag.id}")
  }
}

# THIS RESOURCE ALONE WILL CREATE AND ATTACHED THE IGW TO THE VPC
# SO, THERE IS NO NEED TO CREATE A GW ATTACHMENT
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw_${random_integer.tag.id}"
  }
}

resource "aws_route_table" "my_public_route" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "public-rtb_${random_integer.tag.id}"
  }
  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "pub_sub1_rta" {
  # Retriving the first public subnet id.
  subnet_id      = element(aws_subnet.subnet[*].id, 0) # retrieving the first public subnet ID.
  route_table_id = aws_route_table.my_public_route.id  # and associating it with public rtb
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "pub_sub2_rta" {
  # Retriving the second public subnet id.
  subnet_id      = element(aws_subnet.subnet[*].id, 1) # retrieving the second public subnet ID.
  route_table_id = aws_route_table.my_public_route.id  # and associating it with public rtb
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "pub_sub3_rta" {
  # Retriving the third public subnet id.
  subnet_id      = element(aws_subnet.subnet[*].id, 2) # retrieving the third public subnet ID. 
  route_table_id = aws_route_table.my_public_route.id  # and associating it with public rtb
}

resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.my_vpc.id
  count  = var.private_count
  tags = {
    Name = (count.index < 3 ? "private_rtb_${count.index + 1}"
    : "DataBase_rtb_${count.index - 2}_${random_integer.tag.id}")
  }
}

resource "aws_route_table_association" "private_association" {
  count          = var.priv_assoc_count
  subnet_id      = aws_subnet.subnet[count.index + 3].id
  route_table_id = aws_route_table.my_route[count.index].id
}

resource "aws_route_table_association" "db_association" {
  count          = var.priv_assoc_count
  subnet_id      = aws_subnet.subnet[count.index + 6].id
  route_table_id = aws_route_table.my_route[count.index + 3].id
}


resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.my_tfsec_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.my_vpc.id
  tags = {
    Nane = "my_vpc_flow_log"
  }
}

# CREATE A LINUX2 INTANCE
resource "aws_instance" "linux_server" {
  ami = var.my_ami
  # ami = data.aws_ami.ubuntu.id # REFERENCE THE DATA SOURCE
  metadata_options {
    http_tokens = "required" # Preventing the instance metadata to be interacted with freely
  }
  root_block_device { # Securing sensitive data
    encrypted = true
  }
  subnet_id     = element(aws_subnet.subnet[*].id, 0) # SPECIFY THE SUBNET TO CREATE THE INSTANCE IN.
  instance_type = var.instance_type["dev"]            #REFERENCE THE VALUE OF THE VARIABLE SPECIFIED
  # availability_zone       = data.aws_availability_zone.example.name #data.aws_availability_zone.example.name_suffix) # REFERENCE THE VALUE OF THE VARIABLE SPECIFIED
  availability_zone       = element(data.aws_availability_zones.my_az.names, 0)
  key_name                = var.key_name                             #REFERENCE THE VALUE OF THE VARIABLE SPECIFIED
  disable_api_termination = var.termination                          # THIS IS USED IN PROD IN ORDER TO PROTECT THE SERVER FROM BEING ACCIDENTALLY DESTROY BY TERRAFORM. THE EC2 HAS TO BE TERMINATED MANUALLY ON THE CONSOLE.
  vpc_security_group_ids  = [aws_security_group.ubuntu_server_SG.id] # REFERENCE A RESOURCE
  tags                    = local.EC2_common_tags
}

resource "aws_security_group" "ubuntu_server_SG" {
  name        = var.SG_name
  description = var.SG_description
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = var.ssh_description
    from_port   = var.port_ssh
    to_port     = var.port_ssh
    protocol    = var.protocol
    cidr_blocks = [var.cidr_ssh]
  }

  ingress {
    description = var.http_description
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = var.protocol
    cidr_blocks = [var.cidr_http]
  }
  ingress {
    description = var.db_description
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = var.protocol
    cidr_blocks = [var.cidr_db]
  }

  egress {
    description = var.sg_egress
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    # cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.EC2_common_tags
}

resource "aws_s3_bucket" "my_tfsec_bucket" {
  bucket = "my-tfsec-bucket"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.my_tfsec_bucket.id # Specifies the S3 bucket to apply the public access block settings to.
  block_public_acls       = true                             # Blocks public access via ACLs (Access Control Lists).
  block_public_policy     = true                             # Blocks public access via bucket policies.
  ignore_public_acls      = true                             # Ignores public ACLs, making sure they don't grant public access.
  restrict_public_buckets = true                             # Restricts all public access to the bucket.
}

resource "aws_kms_key" "my_tfsec_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfsec_bucket_encryption" {
  bucket = aws_s3_bucket.my_tfsec_bucket.id # Specifies the S3 bucket to apply server-side encryption settings to.
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_tfsec_key.arn # Specifies the KMS master key to use for encryption.
      sse_algorithm     = "aws:kms"                    # Specifies that the encryption algorithm to use is AWS Key Management Service (KMS).
    }
  }
}

resource "aws_s3_bucket_logging" "tfsec_logging_bucket" {
  bucket        = aws_s3_bucket.my_tfsec_bucket.id
  target_bucket = "mstacwebsti" # Referencing the logging bucket.
  target_prefix = "log/"
}

resource "aws_s3_bucket_versioning" "tfsec_bucket_versioning" {
  bucket = aws_s3_bucket.my_tfsec_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}



