# ===============================================
# Terraform - Infraestructura Base AWS
# Agendamiento Citas Médicas
# ===============================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend para guardar state en S3 (descomentar en producción)
  # backend "s3" {
  #   bucket         = "agendamiento-citas-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AgendamientoCitas"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ===============================================
# Data Sources
# ===============================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ===============================================
# Locals
# ===============================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ===============================================
# VPC y Networking
# ===============================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
  cidr_block  = var.vpc_cidr
  azs         = local.azs
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  tags = local.common_tags
}

# ===============================================
# Security Groups
# ===============================================

module "security_groups" {
  source = "./modules/security-groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  tags = local.common_tags
}

# ===============================================
# DynamoDB
# ===============================================

module "dynamodb" {
  source = "./modules/dynamodb"

  name_prefix = local.name_prefix
  environment = var.environment

  tags = local.common_tags
}

# ===============================================
# RDS MySQL - Perú
# ===============================================

module "rds_peru" {
  source = "./modules/rds"

  name_prefix         = "${local.name_prefix}-pe"
  country            = "PE"
  
  instance_class     = var.rds_instance_class
  allocated_storage  = var.rds_allocated_storage
  engine_version     = var.rds_engine_version
  
  database_name      = var.rds_pe_database_name
  master_username    = var.rds_pe_master_username
  master_password    = var.rds_pe_master_password
  
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.database_subnet_ids
  vpc_security_group_ids  = [module.security_groups.rds_security_group_id]
  
  backup_retention_period = var.rds_backup_retention_period
  multi_az               = var.rds_multi_az
  
  tags = local.common_tags
}

# ===============================================
# RDS MySQL - Chile
# ===============================================

module "rds_chile" {
  source = "./modules/rds"

  name_prefix         = "${local.name_prefix}-cl"
  country            = "CL"
  
  instance_class     = var.rds_instance_class
  allocated_storage  = var.rds_allocated_storage
  engine_version     = var.rds_engine_version
  
  database_name      = var.rds_cl_database_name
  master_username    = var.rds_cl_master_username
  master_password    = var.rds_cl_master_password
  
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.database_subnet_ids
  vpc_security_group_ids  = [module.security_groups.rds_security_group_id]
  
  backup_retention_period = var.rds_backup_retention_period
  multi_az               = var.rds_multi_az
  
  tags = local.common_tags
}

# ===============================================
# SNS Topics
# ===============================================

module "sns" {
  source = "./modules/sns"

  name_prefix = local.name_prefix
  
  tags = local.common_tags
}

# ===============================================
# SQS Queues
# ===============================================

module "sqs" {
  source = "./modules/sqs"

  name_prefix = local.name_prefix
  
  sns_topic_arn_peru  = module.sns.topic_arn_peru
  sns_topic_arn_chile = module.sns.topic_arn_chile
  
  tags = local.common_tags
}

# ===============================================
# EventBridge
# ===============================================

module "eventbridge" {
  source = "./modules/eventbridge"

  name_prefix = local.name_prefix
  
  completion_queue_arn = module.sqs.completion_queue_arn
  
  tags = local.common_tags
}

# ===============================================
# Secrets Manager (para credenciales RDS)
# ===============================================

resource "aws_secretsmanager_secret" "rds_peru" {
  name        = "${local.name_prefix}-rds-peru-credentials"
  description = "RDS Peru database credentials"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_peru" {
  secret_id = aws_secretsmanager_secret.rds_peru.id
  secret_string = jsonencode({
    host     = module.rds_peru.endpoint
    port     = 3306
    database = var.rds_pe_database_name
    username = var.rds_pe_master_username
    password = var.rds_pe_master_password
  })
}

resource "aws_secretsmanager_secret" "rds_chile" {
  name        = "${local.name_prefix}-rds-chile-credentials"
  description = "RDS Chile database credentials"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_chile" {
  secret_id = aws_secretsmanager_secret.rds_chile.id
  secret_string = jsonencode({
    host     = module.rds_chile.endpoint
    port     = 3306
    database = var.rds_cl_database_name
    username = var.rds_cl_master_username
    password = var.rds_cl_master_password
  })
}

# ===============================================
# Outputs para SAM
# ===============================================

resource "local_file" "sam_config" {
  filename = "${path.module}/../sam/infrastructure-outputs.json"
  content = jsonencode({
    VpcId                    = module.vpc.vpc_id
    PrivateSubnetIds         = module.vpc.private_subnet_ids
    LambdaSecurityGroupId    = module.security_groups.lambda_security_group_id
    DynamoDBTableName        = module.dynamodb.table_name
    DynamoDBTableArn         = module.dynamodb.table_arn
    SNSTopicArnPeru         = module.sns.topic_arn_peru
    SNSTopicArnChile        = module.sns.topic_arn_chile
    SQSQueueUrlPeru         = module.sqs.queue_url_peru
    SQSQueueUrlChile        = module.sqs.queue_url_chile
    SQSQueueArnPeru         = module.sqs.queue_arn_peru
    SQSQueueArnChile        = module.sqs.queue_arn_chile
    SQSCompletionQueueUrl   = module.sqs.completion_queue_url
    SQSCompletionQueueArn   = module.sqs.completion_queue_arn
    EventBridgeBusName      = module.eventbridge.bus_name
    RDSPeruSecretArn        = aws_secretsmanager_secret.rds_peru.arn
    RDSChileSecretArn       = aws_secretsmanager_secret.rds_chile.arn
  })
}

