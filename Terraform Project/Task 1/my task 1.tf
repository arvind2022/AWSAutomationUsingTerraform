provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAJ3K3WWCQQPR2HTKQ"
  secret_key = "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"
}


resource "aws_instance" "my-first-instance" {
  ami           = "ami-0a4a70bd98c6d6441"
  instance_type = "t3.micro"
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.first-vpc.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "my-subnet"
  }
} 

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "FIRST VPC"
  }
}

resource "aws_vpc" "second-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "Development"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.second-vpc.id
  cidr_block        = "10.1.1.0/24"

  tags = {
    Name = "dev-subnet"
  }
}




# resource "<provider>_<resource_type>" "name"{
#     config options..........
#     key = "value"
#     key2 = "another value" 
# }

