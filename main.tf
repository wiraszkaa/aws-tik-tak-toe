provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "ec2_kp" {
  key_name   = "ec2_keypair"
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

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "EC2_HIGH_CPU_Alarm"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 30
  evaluation_periods  = 2
  threshold           = 60
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
  alarm_actions = [
    aws_sns_topic.alarm_topic.arn,
    aws_autoscaling_policy.asg_up_policy.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "EC2_LOW_CPU_Alarm"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 30
  evaluation_periods  = 2
  threshold           = 30
  comparison_operator = "LessThanThreshold"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
  alarm_actions = [
    aws_autoscaling_policy.asg_down_policy.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "instance_status_alarm" {
  alarm_name          = "EC2_InstanceStatus_Alarm"
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
  alarm_actions = [
    aws_sns_topic.alarm_topic.arn
  ]
}

resource "aws_sns_topic" "alarm_topic" {
  name = "EC2_Alarm_Topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "266525@student.pwr.edu.pl"
}

resource "aws_launch_template" "ec2_Launch_Template" {
  name          = "EC2_Launch_Template"
  image_id      = "ami-0c101f26f147fa7fd"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ec2_kp.id
  user_data     = filebase64("userdata.sh")
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
    subnet_id                   = aws_subnet.ec2_public.id
  }
}

resource "aws_autoscaling_group" "asg" {
  name               = "EC2_AutoScaling_Group"
  availability_zones = ["us-east-1a"]
  launch_template {
    id      = aws_launch_template.ec2_Launch_Template.id
    version = "$Latest"
  }
  min_size         = 0
  max_size         = 10
  desired_capacity = 1
  enabled_metrics  = ["GroupInServiceInstances"]
}

resource "aws_autoscaling_policy" "asg_up_policy" {
  name                   = "EC2_AutoScaling_Up_Policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 200
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "asg_down_policy" {
  name                   = "EC2_AutoScaling_Down_Policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 200
  autoscaling_group_name = aws_autoscaling_group.asg.name
}
