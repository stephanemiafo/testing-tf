# data "aws_ami" "ubuntu" {
#   most_recent = true             # fetch the most recent ami
#   owners      = ["099720109477"] # account number of the owner of the ami. On the ec2 console click AMI under image section and search your ami id in public images.
#   filter {
#     name   = "name"
#     # values = ["amzn2-ami-kernel-5.10-hvm-2.0.*.1-x86_64-gp2"] # filter by ami name
#   values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"]
#   }
# }

data "aws_availability_zones" "my_az" {
  state = "available"
}
