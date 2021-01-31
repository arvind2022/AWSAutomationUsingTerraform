provider "aws" {
  region     = "ap-south-1"
  access_key = "<access-key>"
  secret_key = "<secret key>"
}

#1. Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Ingress_Gateway"
  }
}

#2. Create Internet Gateway
resource "aws_internet_gateway" "gway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "My_Gateway"
  }
}

#3. Create Routing Table
resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0" #to send all incoming traffic
    gateway_id = aws_internet_gateway.gway.id
  }

  route {
    ipv6_cidr_block        = "::/0" #IPv6 default route
    gateway_id             = aws_internet_gateway.gway.id
  }

  tags = {
    Name = "My_Route_Table"
  }
}

#4. Create a subnet
resource "aws_subnet" "subnet-4" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "My_Subnet"
  }
} 

#5. Associate subnet with Routing Table
resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.subnet-4.id
  route_table_id = aws_route_table.rtable.id
}

#6. Create security group to allow specified ports only to access i.e. port 80 or 443 or 22
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow_web"
  }
}

#7. Create a network interface with the subnet in step 4
resource "aws_network_interface" "web_networks" {
  subnet_id       = aws_subnet.subnet-4.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    Name = "web_networks"
  }
}

#8. Assign elastic IP to the interface to the subnet in step 7
resource "aws_eip" "one" {
  vpc                       = true #Boolean if the EIP is in a VPC or not.
  network_interface         = aws_network_interface.web_networks.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gway] #refer to the whole internet gateway object and not just the id
  
  tags = {
    Name = "one"
  }
}

#9. Create a Ubuntu server and install apache2 in it
resource "aws_instance" "ubuntu_server_instance"{
  ami                  = "ami-0a4a70bd98c6d6441"
  instance_type        = "t2.micro"
  availability_zone    = "ap-south-1a" 
  key_name             = "my-sec-key"

  network_interface{
    device_index = 0
    network_interface_id = aws_network_interface.web_networks.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo My first web server > /var/www/html/index.html'
                EOF
                
  tags = {
    Name = "ubuntu_server_instance"
  }
}
