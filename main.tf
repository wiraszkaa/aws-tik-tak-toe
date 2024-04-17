provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "fg_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "fg_public" {
  vpc_id            = aws_vpc.fg_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "fg_igw" {
  vpc_id = aws_vpc.fg_vpc.id
}

resource "aws_route_table" "fg_rt" {
  vpc_id = aws_vpc.fg_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fg_igw.id
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.fg_public.id
  route_table_id = aws_route_table.fg_rt.id
}

resource "aws_security_group" "fg_sg" {
  vpc_id      = aws_vpc.fg_vpc.id
  name        = "fg_instance_security_group"
  description = "Security Group for Tik Tak Toe Instance"

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

resource "aws_ecr_repository" "repo" {
  name = "ecr-repo"
}

data "aws_caller_identity" "current" {}

resource "null_resource" "authenticate_docker" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com"
  }
}

resource "null_resource" "push_frontend_image" {
  depends_on = [null_resource.authenticate_docker]

  provisioner "local-exec" {
    command = <<EOF
      docker build -t ${aws_ecr_repository.repo.repository_url}/tik-tak-toe-frontend:latest .
      docker push ${aws_ecr_repository.repo.repository_url}/tik-tak-toe-frontend:latest
    EOF
  }
}

resource "null_resource" "push_backend_image" {
  depends_on = [null_resource.authenticate_docker]

  provisioner "local-exec" {
    command = <<EOF
      docker build -t ${aws_ecr_repository.repo.repository_url}/tik-tak-toe-backend:latest .
      docker push ${aws_ecr_repository.repo.repository_url}/tik-tak-toe-backend:latest
    EOF
  }
}

resource "aws_ecs_task_definition" "tik-tak-toe-backend_task" {
  depends_on = [null_resource.push_backend_image]

  family                   = "tik-tak-toe-backend-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "tik-tak-toe-backend-container"
      image     = join("", aws_ecr_repository.repo.repository_url, "/tik-tak-toe-backend:latest")
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          name  = "PORT"
          value = "8080"
        }
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "tik-tak-toe-backend_service" {
  name            = "tik-tak-toe-backend-service"
  cluster         = "tik-tak-toe"
  task_definition = aws_ecs_task_definition.tik-tak-toe-backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.fg_public.id]
    security_groups  = [aws_security_group.fg_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.tik-tak-toe-backend_task]
}

resource "aws_ecs_task_definition" "tik-tak-toe-frontend_task" {
  depends_on = [null_resource.push_frontend_image]

  family                   = "tik-tak-toe-frontend-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "tik-tak-toe-frontend-container"
      image     = join("", aws_ecr_repository.repo.repository_url, "/tik-tak-toe-frontend:latest")
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          name  = "PORT"
          value = "80"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "tik-tak-toe-frontend_service" {
  name            = "tik-tak-toe-frontend-service"
  cluster         = "tik-tak-toe"
  task_definition = aws_ecs_task_definition.tik-tak-toe-frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.fg_public.id]
    security_groups  = [aws_security_group.fg_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.tik-tak-toe-frontend_task]
}