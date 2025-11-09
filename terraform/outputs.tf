# ===============================================
# Outputs - Terraform
# ===============================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.appointments.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.appointments.arn
}

output "rds_peru_endpoint" {
  description = "RDS Peru endpoint"
  value       = aws_db_instance.peru.endpoint
}

output "rds_chile_endpoint" {
  description = "RDS Chile endpoint"
  value       = aws_db_instance.chile.endpoint
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
  value       = aws_sns_topic.peru.arn
}

output "sns_topic_arn_chile" {
  description = "SNS Topic ARN for Chile"
  value       = aws_sns_topic.chile.arn
}

output "sqs_queue_url_peru" {
  description = "SQS Queue URL for Peru"
  value       = aws_sqs_queue.peru.url
}

output "sqs_queue_url_chile" {
  description = "SQS Queue URL for Chile"
  value       = aws_sqs_queue.chile.url
}

output "sqs_queue_arn_peru" {
  description = "SQS Queue ARN for Peru"
  value       = aws_sqs_queue.peru.arn
}

output "sqs_queue_arn_chile" {
  description = "SQS Queue ARN for Chile"
  value       = aws_sqs_queue.chile.arn
}

output "sqs_completion_queue_url" {
  description = "SQS Completion Queue URL"
  value       = aws_sqs_queue.completion.url
}

output "sqs_completion_queue_arn" {
  description = "SQS Completion Queue ARN"
  value       = aws_sqs_queue.completion.arn
}

output "eventbridge_bus_name" {
  description = "EventBridge Bus Name"
  value       = aws_cloudwatch_event_bus.main.name
}

output "lambda_security_group_id" {
  description = "Security Group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  value       = aws_subnet.private[*].id
}
