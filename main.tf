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

resource "aws_elastic_beanstalk_application" "frontend_app" {
  name        = "tik-tak-toe-frontend"
  description = "Frontend Application"
}

resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "frontend-env"
  application         = aws_elastic_beanstalk_application.frontend_app.name
  solution_stack_name = "64bit Amazon Linux 2 v5.4.5 running Node.js 14"
  cname_prefix        = "frontend"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.nano"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "SecurityGroups"
    value     = aws_security_group.frontend_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "Subnets"
    value     = aws_subnet.ec2_public.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "KeyName"
    value     = aws_key_pair.ec2_kp.id
  }
}

resource "aws_elastic_beanstalk_application" "backend_app" {
  name        = "tik-tak-toe-backend"
  description = "Backend Application"
}

resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "backend-env"
  application         = aws_elastic_beanstalk_application.backend_app.name
  solution_stack_name = "64bit Amazon Linux 2 v5.4.5 running Node.js 14"
  cname_prefix        = "backend"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.nano"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentVariables"
    value     = "PORT=8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "SecurityGroups"
    value     = aws_security_group.backend_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "Subnets"
    value     = aws_subnet.ec2_public.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "KeyName"
    value     = aws_key_pair.ec2_kp.id
  }
}

resource "aws_security_group" "frontend_sg" {
  vpc_id      = aws_vpc.ec2_vpc.id
  name        = "frontend-instance-security-group"
  description = "Security Group for Frontend Elastic Beanstalk Environment"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  vpc_id      = aws_vpc.ec2_vpc.id
  name        = "backend-instance-security-group"
  description = "Security Group for Backend Elastic Beanstalk Environment"

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