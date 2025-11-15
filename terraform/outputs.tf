output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "Public ALB DNS for the app"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}
