# ===============================================
# Outputs - Terraform
# ===============================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}

output "rds_peru_endpoint" {
  description = "RDS Peru endpoint"
  value       = module.rds_peru.endpoint
}

output "rds_chile_endpoint" {
  description = "RDS Chile endpoint"
  value       = module.rds_chile.endpoint
}

output "rds_peru_secret_arn" {
  description = "ARN of RDS Peru credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.rds_peru.arn
}

output "rds_chile_secret_arn" {
  description = "ARN of RDS Chile credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.rds_chile.arn
}

output "sns_topic_arn_peru" {
  description = "SNS Topic ARN for Peru"
  value       = module.sns.topic_arn_peru
}

output "sns_topic_arn_chile" {
  description = "SNS Topic ARN for Chile"
  value       = module.sns.topic_arn_chile
}

output "sqs_queue_url_peru" {
  description = "SQS Queue URL for Peru"
  value       = module.sqs.queue_url_peru
}

output "sqs_queue_url_chile" {
  description = "SQS Queue URL for Chile"
  value       = module.sqs.queue_url_chile
}

output "eventbridge_bus_name" {
  description = "EventBridge Bus Name"
  value       = module.eventbridge.bus_name
}

output "lambda_security_group_id" {
  description = "Security Group ID for Lambda functions"
  value       = module.security_groups.lambda_security_group_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  value       = module.vpc.private_subnet_ids
}

