variable "aws_region" {
  type        = string
  description = "The region in which to create and manage resources"
  default     = "eu-central-1"
}


variable "vpc_cidr" {
  default = "10.100.0.0/16"
}

variable "azs" {
  type = list(string)
  description = "the name of availability zones to use subnets"
  default = [ "eu-central-1a", "eu-central-1b" ]
}

variable "public_subnets" {
  type = list(string)
  description = "the CIDR blocks to create public subnets"
  default = [ "10.100.10.0/24", "10.100.20.0/24" ]
}

variable "private_subnets" {
  type = list(string)
  description = "the CIDR blocks to create private subnets"
  default = [ "10.100.30.0/24", "10.100.40.0/24" ]
}

variable "cluster_name" {
  type = string
  description = "The fargate cluster name"
  default = "fargare-nginx"
}

variable "service_name" {
  type = string
  description = "The fargate service name"
  default = "nginx-service"
}

variable "service_port" {
  type = number
  description = "The port to fargate service"
  default = 80
}

variable "image_name" {
  type = string
  description = "The image of fargate"
  default = "nginx"
}
