resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow SSH and HTTP"
  vpc_id      = module.ecs_vpc.vpc_id
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "local_file" "cloud_pem" { 
#   filename = "/home/bohdan/devops/techmagic/Homework5/clear_project/ec2-efs-access-key.pem"
#   content = tls_private_key.key.private_key_pem
# }

# resource "tls_private_key" "key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "generated_key" {
#   key_name   = "ec2-efs-access-key"
#   public_key = tls_private_key.key.public_key_openssh
# }


module "ec2-instance-with-efs" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "efs-instance"

  ami                    = "ami-0e2031728ef69a466"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id, aws_security_group.ec2_efs_sg.id]
  subnet_id              = module.ecs_vpc.public_subnets[0]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  depends_on = [
    module.efs
  ]
}

resource "null_resource" "configure_nfs" {
  depends_on = [module.ec2-instance-with-efs]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("./tm-piar.pem")
    host     = module.ec2-instance-with-efs.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "echo ${module.efs.efs_endpoint}",
      "ls -la",
      "pwd",
      "sudo mkdir -p mount-point",
      "ls -la",
      "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${module.efs.efs_endpoint}:/ mount-point",
      "ls",
      "sudo chown -R ec2-user.ec2-user mount-point",      
      "cd mount-point",
      "echo '<html> <head>Static</head> <body> <h1>Hello World</h1> <h1>Hello World2</h1> </body> </html>' > index.html"
    ]
  }
}