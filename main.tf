#defining the key pair 
resource "aws_key_pair" "andlanc-keypair" {
  key_name   = "andlanc_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
  tags = {
    Name = "andlanc-keypair"
  }
}

#creating the vpc
resource "aws_vpc" "andlanc-vpc" {
  cidr_block = var.andlanc-cidr

  tags = {
    Name = "andlanc-vpc"
  }
}

#creating internet gateway for the vpc
resource "aws_internet_gateway" "andlanc-internet-gateway" {
  vpc_id = aws_vpc.andlanc-vpc.id

  tags = {
    Name = "andlanc-internet-gateway"
  }
}

#creating the route table
resource "aws_route_table" "andlanc-route-table" {
  vpc_id = aws_vpc.andlanc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.andlanc-internet-gateway.id
  }

  tags = {
    Name = "andlanc-route-table"
  }
}

#creating the subnet (public subnet)
resource "aws_subnet" "andlanc-subnet" {
  vpc_id            = aws_vpc.andlanc-vpc.id
  cidr_block        = var.andlanc-subnet-cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "andlanc-subnet"
  }
}

#associate subnet to route table
resource "aws_route_table_association" "andlanc-route-table-association" {
  subnet_id      = aws_subnet.andlanc-subnet.id
  route_table_id = aws_route_table.andlanc-route-table.id
}


#creating your network interface
resource "aws_network_interface" "andlanc-nic" {
  subnet_id       = aws_subnet.andlanc-subnet.id
  private_ips     = ["10.1.0.50"]
  security_groups = [aws_security_group.andlanc-allow-web-traffic.id]

}

#creating and assigning your elastic ip 
resource "aws_eip" "andlanc-test-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.andlanc-nic.id
  associate_with_private_ip = "10.1.0.50"
  depends_on                = [aws_internet_gateway.andlanc-internet-gateway]
}

#creating the the instance and launching your webserver
resource "aws_instance" "andlanc" {
  ami               = "ami-0440d3b780d96b29d"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "andlanc_keypair"

  network_interface {
    network_interface_id = aws_network_interface.andlanc-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo yum install git -y
    cd /home/ec2-user/
    git clone https://yawnartey:<>@github.com/yawnartey/andlanc-web
    sudo cp -r /home/ec2-user/andlanc-web/* /var/www/html/
    EOF

  tags = {
    Name = "andlanc"
  }
}


#creating your security group
resource "aws_security_group" "andlanc-allow-web-traffic" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.andlanc-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "andlanc-allow-web-traffic"
  }
}