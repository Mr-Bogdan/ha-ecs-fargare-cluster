locals {
  efs_name = "efs-ecs-fargate"
}

module "efs" {
  source = "git::https://github.com/terraform-iaac/terraform-aws-efs?ref=v2.0.4"

  name         = local.efs_name
  vpc_id       = module.ecs_vpc.vpc_id
  subnet_ids   = module.ecs_vpc.private_subnets
  whitelist_sg = ["${aws_security_group.ecs_task_sg.id}", "${aws_security_group.ec2_efs_sg.id}"]
}

resource "aws_security_group" "ec2_efs_sg" {
  name   = "efs-ec2-sg"
  vpc_id = module.ecs_vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 64000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "test-sg-ec2"
  }
}
