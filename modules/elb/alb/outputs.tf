output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "security_group_id" {
  value = var.security_group_id
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "test_listener_arn" {
  value = aws_lb_listener.test.arn
}