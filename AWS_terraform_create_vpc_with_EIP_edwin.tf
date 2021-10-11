#Access AWS 

provider "aws" {
 region = "ap-southeast-1"
 access_key = "AKIA5AGZYOPE6CYCTLU6"
  secret_key = "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"
}

#Environment Variable 

variable "instance_type_id01" {
  description = "Instance type to use"
  default = "t2.micro"
}

variable "instance_type_id02" {
  description = "Instance type to use"
  default = "t3.micro"
}


variable "ami_id" {
  description = "AMI ID"
  #default = "ami-0c3fdfab1d017616b"
  default = "ami-0e322e4412d2a52e7"
}


#Create VPC

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "my_vpc"
  }
}

#Create Private Subnet 
resource "aws_subnet" "subnet_pvt" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "subnet_pvt"
  }
}

#Create Public Subnet 
resource "aws_subnet" "subnet_pub" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "my_subnet_pub"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "igw_01" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_Igw01"
  }
}


#Routing table

resource "aws_route_table" "my_route_table_pub_01" {
  vpc_id = aws_vpc.my_vpc.id
   route  {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw_01.id
    }
   
  tags = {
    Name = "my_route_table_pub_01"
  }
}

resource "aws_route_table_association" "route_table_ass01" {
  subnet_id     = aws_subnet.subnet_pub.id
  route_table_id = aws_route_table.my_route_table_pub_01.id
}


#EIP 

resource "aws_eip" "my_eip01" {
  vpc      = true
  tags = { 
	Name = "my_eip01"
	}
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.application02.id
  allocation_id = aws_eip.my_eip01.id
}


#Create Security group
resource "aws_security_group" "allow_sg" {
name = "allow_sg"
vpc_id = aws_vpc.my_vpc.id

ingress { 
description = "allow_ssh_sg"
from_port = 22
to_port   = 22
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress { 
description = "allow_http_sg"
from_port = 80
to_port   = 80
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "allow_sg"
}

egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}


#Instance create 

resource "aws_instance" "application01" {
   #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id01}"
   ami = "${var.ami_id}"
   subnet_id = aws_subnet.subnet_pvt.id
   key_name = "ansible"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
   user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y 
  sudo apt install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  echo "*** Completed Installing apache1"
  EOF
tags = {
	Name = "application_instance01_pvt"
}

volume_tags = {
	Name = "application_instance_private"
}
}

resource "aws_instance" "application02" {
  #instance_type = "t2.micro"
   instance_type = "${var.instance_type_id01}"
   ami = "${var.ami_id}"
   subnet_id = aws_subnet.subnet_pub.id
   key_name = "ansible"
   vpc_security_group_ids = [aws_security_group.allow_sg.id]
    user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y 
  sudo apt install haproxy -y
  sudo yum install -y httpd httpd-tools mod_ssl 
  sudo amazon-linux-extras install ansible2
  yum install nginx -y
  yum install git -y
  echo "*** Completed Installing apache2"
  EOF
tags = {
	Name = "application_instance02_pub"
}

volume_tags = {
	Name = "application_instance_pub"
}
}

