terraform {
  
  required_providers {
    
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

  }

  backend "s3" {
    bucket                  = "zero-hash-tech-assessment"
    key                     = "zero-hash-tech-assessment.tfstate"
    region                  = "us-east-2"
    profile                 = # REMOVED
    role_arn                = # REMOVED
  }

}

provider "aws" {
  region                    = "us-east-2"
  profile                   = # REMOVED
}

## ------------------------------------------------------------------------------------------------------------------------
## security groups

resource "aws_security_group" "ecs_alb_security_group" {
  name        = var.alb_sg_name
  description = "Security group for the alb that forwards requests to the ecs services"
  vpc_id      = var.vpc_id

  ingress {
    description      = "http ingress from the vpc cidr"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.cidr_block
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.cidr_block
  }

  tags = {
    Name = var.alb_sg_name
  }
}

resource "aws_security_group" "ecs_services_security_group" {
  name        = var.ecs_sg_name
  description = "Security group for the ecs services"
  vpc_id      = var.vpc_id

  ingress {
    description      = "http ingress from the vpc cidr"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups  = [ aws_security_group.ecs_alb_security_group.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.cidr_block
  }

  tags = {
    Name = var.ecs_sg_name
  }
}

## ------------------------------------------------------------------------------------------------------------------------
## alb

resource "aws_lb" "ecs_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.ecs_alb_security_group.id ]
  subnets            = var.public_subnets

  enable_deletion_protection = true

  tags = {
    Name        = var.alb_name
  }
}

## ------------------------------------------------------------------------------------------------------------------------
## alb target group

resource "aws_lb_target_group" "ecs_service_target_group" {
  name                  = var.target_group_name
  deregistration_delay  = 10
  port                  = var.container_port
  protocol              = "HTTP"
  target_type           = "ip"
  vpc_id                = var.vpc_id

  health_check {
    healthy_threshold = 2
    interval = 30
    matcher = "200,301,302"
    path = "/health"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 20
    unhealthy_threshold = 5
  }

  stickiness {
    enabled = false
    type = "lb_cookie"
  }

}

## ------------------------------------------------------------------------------------------------------------------------
## alb listener

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_service_target_group.arn
  }

}

## ------------------------------------------------------------------------------------------------------------------------
## iam role

resource "aws_iam_role" "ecs_iam_role" {
  name = var.iam_role_name
  managed_policy_arns = var.iam_managed_policies

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "ecs_iam_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
              "application-autoscaling:*",
              "cloudwatch:DescribeAlarms",
              "cloudwatch:PutMetricAlarm",
              "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
              "elasticloadbalancing:DeregisterTargets",
              "elasticloadbalancing:Describe*",
              "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
              "elasticloadbalancing:RegisterTargets",
              "ec2:Describe*",
              "ec2:AuthorizeSecurityGroupIngress",
              "ecs:DescribeServices",
              "ecs:UpdateService"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

}

## ------------------------------------------------------------------------------------------------------------------------
## ecs cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

## ------------------------------------------------------------------------------------------------------------------------
## cloudwatch log group

resource "aws_cloudwatch_log_group" "ecs_service_log_group" {
  name = var.cw_log_group_name
}

## ------------------------------------------------------------------------------------------------------------------------
## ecs task definition

resource "aws_ecs_task_definition" "ecs_task_definition" {
  container_definitions = <<DEFINITION
  [
    {
        "name": "${var.container_name}",
        "image": "${var.docker_image}",
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-region": "us-east-2",
                "awslogs-group": "${var.cw_log_group_name}",
                "awslogs-stream-prefix": "${var.ecs_service_name}"
            }
        },
        "portMappings": [
            {
                "containerPort": ${var.container_port}
            }
        ]
    }
  ]
  DEFINITION
  
  cpu = var.task_cpu
  execution_role_arn = aws_iam_role.ecs_iam_role.arn
  memory = var.task_memory
  family = var.task_definition_name
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
}

## ------------------------------------------------------------------------------------------------------------------------
## ecs service

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = var.tasks_scaling_desired
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_service_target_group.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets = var.private_subnets
    security_groups = [ aws_security_group.ecs_services_security_group.id ]
    assign_public_ip = false
  }

  depends_on      = [ aws_iam_role.ecs_iam_role ]

}