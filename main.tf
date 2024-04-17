provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_instance_profile" "lab_profile" {
  name = "LabProfile"
  role = "LabRole"
}

resource "aws_vpc" "eb_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eb_public" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "eb_public2" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "backend_sg" {
  name        = "backend_security_group"
  description = "Backend Security Group"
  vpc_id      = aws_vpc.eb_vpc.id

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_internet_gateway" "eb_igw" {
  vpc_id = aws_vpc.eb_vpc.id
}

resource "aws_route_table" "eb_rt" {
  vpc_id = aws_vpc.eb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eb_igw.id
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.eb_public.id
  route_table_id = aws_route_table.eb_rt.id
}

resource "aws_route_table_association" "subnet_association2" {
  subnet_id      = aws_subnet.eb_public2.id
  route_table_id = aws_route_table.eb_rt.id
}

data "archive_file" "frontend_archive" {
  type        = "zip"
  source_dir  = "frontend"
  output_path = "frontend.zip"
  excludes    = ["node_modules", ".env", "dist"]
}

data "archive_file" "backend_archive" {
  type        = "zip"
  source_dir  = "backend"
  output_path = "backend.zip"
  excludes    = ["node_modules", ".env"]
}

resource "aws_s3_bucket" "tik-tak-toe-bucket" {
  bucket = "tik-tak-toe-bucket"
}

resource "aws_s3_object" "s3_frontend_object" {
  bucket = aws_s3_bucket.tik-tak-toe-bucket.id
  key    = "frontend.zip"
  source = "frontend.zip"
  # etag   = filemd5("frontend.zip")
}

resource "aws_s3_object" "s3_backend_object" {
  bucket = aws_s3_bucket.tik-tak-toe-bucket.id
  key    = "backend.zip"
  source = "backend.zip"
  # etag   = filemd5("backend.zip")
}

resource "aws_elastic_beanstalk_application" "frontend_app" {
  name        = "tik-tak-toe-frontend"
  description = "Frontend Application"
}

resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "frontend-env"
  application         = aws_elastic_beanstalk_application.frontend_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.1.2 running Node.js 20"
  cname_prefix        = "tik-tak-toe-frontend"
  version_label       = aws_elastic_beanstalk_application_version.frontend_app_version.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "arn:aws:iam::058264464411:role/aws-service-role/elasticbeanstalk.amazonaws.com/AWSServiceRoleForElasticBeanstalk"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.lab_profile.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.nano"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.eb_public.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = aws_subnet.eb_public.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "True"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "VITE_WS_URL"
    value     = "ws://52.55.237.177:4000"
  }
}

resource "aws_elastic_beanstalk_application_version" "frontend_app_version" {
  name        = "tik-tak-toe-frontend_version"
  application = aws_elastic_beanstalk_application.frontend_app.name
  bucket      = aws_s3_bucket.tik-tak-toe-bucket.id
  key         = aws_s3_object.s3_frontend_object.id
}

resource "aws_elastic_beanstalk_application" "backend_app" {
  name        = "tik-tak-toe-backend"
  description = "Backend Application"
}

resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "backend-env"
  application         = aws_elastic_beanstalk_application.backend_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.1.2 running Node.js 20"
  cname_prefix        = "tik-tak-toe-backend"
  version_label       = aws_elastic_beanstalk_application_version.backend_app_version.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "arn:aws:iam::058264464411:role/aws-service-role/elasticbeanstalk.amazonaws.com/AWSServiceRoleForElasticBeanstalk"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.lab_profile.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.nano"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.backend_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.eb_public.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = aws_subnet.eb_public.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "True"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "4000"
  }
}

resource "aws_elastic_beanstalk_application_version" "backend_app_version" {
  name        = "tik-tak-toe-backend_version"
  application = aws_elastic_beanstalk_application.backend_app.name
  bucket      = aws_s3_bucket.tik-tak-toe-bucket.id
  key         = aws_s3_object.s3_backend_object.id
}
