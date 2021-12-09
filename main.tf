provider "aws" {
  profile    = "${var.profile}"
  region     = "${var.region}"
}

variable my_ip {}
variable public_key_loc {}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Dev-Vpc"
  }
}

resource "aws_subnet" "dev-app" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.0.1.0/24"
  availability_zone =  "eu-west-1a"
  tags = {
    Name = "Dev-Subnet"
  }
}

resource "aws_route_table" "dev-route" {
  vpc_id = aws_vpc.dev.id
  
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }
  tags = {
    Name = "dev-routetable"
  }
}

resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.dev.id
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.dev-app.id
  route_table_id = aws_route_table.dev-route.id
}

resource "aws_security_group" "dev-sg" {
  name        = "dev-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "devsg"
  }
}

data "aws_ami" "latest-amazon-limux-image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}

resource "aws_instance" "webapp" {
     ami = data.aws_ami.latest-amazon-limux-image.id
     instance_type = "t2.micro"
     subnet_id = aws_subnet.dev-app.id
     vpc_security_group_ids = [aws_security_group.dev-sg.id]
     availability_zone = "eu-west-1a"
     associate_public_ip_address = true
     key_name = aws_key_pair.ssh-key.key_name

     user_data = <<EOF
                #!/bin/bash
                sudo yum update -y && sudo yum install docker -y
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                docker run -p 8080:80 nginx
            EOF

    tags = {
  name = "dev-awsserver"
}
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-keyyy"
    public_key = "${file(var.public_key_loc)}"

}

