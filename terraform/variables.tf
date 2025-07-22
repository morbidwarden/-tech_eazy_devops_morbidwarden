variable "aws_region"{
    default = "ap-south-1"
}
variable "ami"{
    default = "ami-0b32d400456908bf9"
}
variable "vpc_cidr"{
    default = "10.0.0.0/16"
}
variable "availability_zone" {
  default = "ap-south-1b"
}
variable "instance_type" {
  default = "t2.micro"
}
