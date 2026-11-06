variable "aws_region" {
  type = string
  default = "ap-south-1"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  type = string
}