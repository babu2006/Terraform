provider "aws" {
  profile    = "${var.profile}"
  region     = "${var.region}"
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev-1" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  availability_zone =  "eu-west-1a"
  tags = {
    Name = "Main"
  }
}

data "aws_vpc" "existing" {
  default = true
}

resource "aws_subnet" "dev-2" {
  vpc_id     = data.aws_vpc.existing.id
  cidr_block = "172.31.48.0/20"
  availability_zone =  "eu-west-1a"
  tags = {
    Name = "Default"
  }
}