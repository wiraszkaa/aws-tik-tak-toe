provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "ec2_kp" {
    key_name = "ec2_keypair"
    public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "TF-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "ec2_rsa"
}

resource "aws_instance" "tik-tak-toe_ec2" {
  ami           = "ami-0c101f26f147fa7fd" 
  instance_type = "t2.nano"               

  tags = {
    Name     = "tik-tak-toe EC2 instance"
    Frontend = "React.js"
    Backend  = "Node.js"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  subnet_id = aws_subnet.ec2_public.id

  depends_on                  = [aws_internet_gateway.ec2_igw]
  associate_public_ip_address = true

  key_name = aws_key_pair.ec2_kp.id
}

resource "aws_security_group" "ec2_sg" {
  vpc_id      = aws_vpc.ec2_vpc.id
  name        = "ec2_instance_security_group"
  description = "Security Group for Tik Tak Toe EC2 Instance"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "ec2_vpc" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "ec2_public" {
  vpc_id            = aws_vpc.ec2_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "ec2_igw" {
  vpc_id = aws_vpc.ec2_vpc.id
}

resource "aws_route_table" "ec2_rt" {
  vpc_id = aws_vpc.ec2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ec2_igw.id
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.ec2_public.id
  route_table_id = aws_route_table.ec2_rt.id
}
