resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


locals {
  task_def_name = "nginx-conatiner"
  aws_account_id = "684937787973"
  ecs_service_sg_name = "nginx-ecs-service-sg"
}

resource "aws_ecs_cluster" "ecs_fargate" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "nginx-ecs-task-definition" {
  family                   = local.task_def_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::${local.aws_account_id}:role/ecsTaskExecutionRole"
  memory                   = 1024
  cpu                      = 512
  container_definitions = jsonencode([
    {
      name      = "${var.image_name}"
      image     = "${var.image_name}:alpine"
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = var.service_port
          hostPort      = var.service_port
        }
      ]
      environment = [
        {
          "name" : "TEST_ENV",
          "value" : "test"
        },
      ]
      mountPoints = [
        {
          "readOnly": false,
          "containerPath": "/usr/share/nginx/html",
          "sourceVolume": "efs"
        }
      ]
    }
  ])
  volume {
    name = "efs"

    efs_volume_configuration {
      file_system_id          = "${module.efs.efs_id}"
      transit_encryption      = "DISABLED"
      root_directory          = "/"
      authorization_config {
        iam             = "DISABLED"
      }
    }
  }
  tags = merge(
    local.common_tags,
    {
      Name = local.task_def_name
    }
  )
}


resource "aws_security_group" "ecs_task_sg" {
  name   = local.ecs_service_sg_name
  vpc_id = module.ecs_vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = ["${aws_security_group.alb_sg.id}"] 
  } 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = local.ecs_service_sg_name
  }
}

resource "aws_ecs_service" "nginx-ecs-service" {
  name                               = var.service_name
  cluster                            = aws_ecs_cluster.ecs_fargate.id
  task_definition                    = aws_ecs_task_definition.nginx-ecs-task-definition.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  platform_version                   = "1.4.0"
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_task_sg.id}"]
    subnets          = module.ecs_vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
    container_name   = var.image_name
    container_port   = var.service_port
  }
}
ajasdnajsdno
asdasdnao
