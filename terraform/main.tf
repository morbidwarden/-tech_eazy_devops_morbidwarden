terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
        Name="my-vpc"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public subnet"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "My-Internet-Gateway"
  }
}
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
  tags = {
    Name = "Route Table"
  }
}
// attaching association with the route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.my-rt.id
}



resource "aws_instance" "PublicInstance" {
  ami           = var.ami
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  subnet_id   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name = "keypair"
  user_data              = templatefile("${path.module}/../scripts/user_data.tmpl.sh", {
  bucket_name = var.bucket_name
})
  tags = {
    Name = "public instance 01"
  }
}
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow SSH & HTTP"
  }
}

## s3 configuration

//write only iam role
resource "aws_iam_role" "s3_upload_only_role" {
  name = "S3UploadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
//s3 policy

resource "aws_iam_role_policy" "s3_upload_only_policy" {
  name = "S3UploadOnlyPolicy"
  role = aws_iam_role.s3_upload_only_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:CreateBucket",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      {
        Effect = "Deny"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

// s3 pollicy attachment

# resource "aws_iam_role_policy_attachment" "writeonly_attach" {
#     role = aws_iam_role.s3_upload_only_role
#     policy_arn = aws_iam_policy.s3_upload_only_policy.arn
  
# }
// profile configuration 

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "example-ec2-instance-profile"
  role = aws_iam_role.s3_upload_only_role.name
}
// creating s3 bucket
resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
  force_destroy = true
  tags = {
    Name = "ec2-logs-bucket"
  }
}
// ownership
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
// lifecycle configuration 
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rule" {
  bucket = aws_s3_bucket.logs.id
  rule{
    id = "delete-logs"
    status = "Enabled"
    expiration{
      days = 7
    }  
    filter {
      prefix = ""
    }
  }
}


//read only profile 

resource "aws_iam_role" "s3_read_only_role" {
  name = "S3ReadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_read_only_policy" {
  name = "S3ReadOnlyPolicy"
  role = aws_iam_role.s3_read_only_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"
      ]
    }]
  })
}


resource "aws_iam_instance_profile" "readonly_profile" {
    name = "ec2-readonly-profile"
    role = aws_iam_role.s3_read_only_role.name 
}

resource "aws_instance" "readonly_ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = "keypair"
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile = aws_iam_instance_profile.readonly_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli
              sleep 30
              echo "Listing logs from S3..." > /home/ec2-user/readonly_check.log
              sudo aws s3 ls s3://${var.bucket_name}/app/logs/ >> /home/ec2-user/readonly_check.log
              sudo aws s3 ls s3://${var.bucket_name}/system/ >> /home/ec2-user/readonly_check.log
              EOF

  tags = {
    Name = "techeazy-readonly-instance"
  }   
}  