
# LOCAL BLOCK WITH ENVIRONMENT AS A LIST OF STRING
locals {
  EC2_common_tags = {
    Name       = "Ubuntu_server-${var.aws_region}-${var.aws_env["0"]}" # ENV IS A LIST OF STRING. 
    Region     = var.aws_region
    AZ         = "${var.aws_region}a"
    Managed_By = "Terraform"
  }
}

# LOCAL BLOCK WITH ENVIRONMENT AS A MAP OF STRING
# locals {
#   EC2_common_tags = {
#     Name = "linux_server-${var.aws_region}-${var.aws_env["Braining"]}"  # ENV IS A MAP OF STRING ${var.aws_env ["Braining"]}
#     Region = "${var.aws_region}"
#     AZ = "${var.aws_region}b"
#     Managed_By = "Terraform"
#   }
# }

locals {
  vpc_tags = {
    Name       = "my_vpc-${random_integer.tag.id}-${var.aws_region}-${var.aws_env["0"]}"
    Managed_By = "Terraform"
    Region     = var.aws_region
  }
}