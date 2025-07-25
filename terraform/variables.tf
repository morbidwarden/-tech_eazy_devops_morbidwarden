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
  default = "t3.micro"
}
variable "bucket_name" {
  description = "The name of the S3 bucket to store logs"
  type        = string

  validation {
    condition     = length(var.bucket_name) > 3
    error_message = "Bucket name must be at least 4 characters long."
  }
}