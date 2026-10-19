output "asg_id" {
  description = "The Auto Scaling Group ID"
  value       = aws_autoscaling_group.app_asg.id
}

output "asg_name" {
  description = "The Auto Scaling Group Name"
  value       = aws_autoscaling_group.app_asg.name
}