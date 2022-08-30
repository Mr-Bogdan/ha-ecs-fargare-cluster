output "alb_endpoint" {
  value = aws_lb.ecs_alb.dns_name
}