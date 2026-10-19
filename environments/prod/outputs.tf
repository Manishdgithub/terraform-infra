output "alb_dns_name" {
  description = "Public URL of Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "key_pair_name" {
  description = "The registered EC2 Key Pair name"
  value       = aws_key_pair.aws_login.key_name
}

output "private_key_file_path" {
  description = "Local path to the downloaded private SSH .pem key"
  value       = local_file.private_pem.filename
}

output "s3_bucket_arn" {
  description = "ARN of the created regional S3 bucket"
  value       = module.regional_services.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.regional_services.dynamodb_table_name
}