output "alb_security_group_id" {
  description = "The security group ID attached to the ALB"
  value       = aws_security_group.alb_sg.id
}

output "instance_security_group_id" {
  description = "The security group ID attached to backend application servers"
  value       = aws_security_group.instance_sg.id
}