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

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
      Type = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
      Type = "private"
    }
  )
}

resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-subnet-${count.index + 1}"
      Type = "database"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-rt"
    }
  )
}

resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-subnet-group"
    }
  )
}

# ===============================================
# Security Groups
# ===============================================

resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-lambda-sg"
    }
  )
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-sg"
    }
  )
}

# ===============================================
# DynamoDB
# ===============================================

resource "aws_dynamodb_table" "appointments" {
  name         = "${local.name_prefix}-appointments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "insuredId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "insuredId-createdAt-index"
    hash_key        = "insuredId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-appointments"
    }
  )
}

# ===============================================
# RDS MySQL - Perú
# ===============================================

resource "aws_db_instance" "peru" {
  identifier     = "${local.name_prefix}-rds-pe"
  engine         = "mysql"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.rds_pe_database_name
  username = var.rds_pe_master_username
  password = var.rds_pe_master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  multi_az               = var.rds_multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
  deletion_protection    = var.environment == "prod"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-rds-pe"
      Country = "PE"
    }
  )

  # Timeouts para operaciones de RDS
  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }

  # Lifecycle para evitar modificaciones cuando la instancia no está disponible
  lifecycle {
    create_before_destroy = false
    # Ignorar cambios en password después de la creación inicial
    # (para evitar actualizaciones no deseadas después de importar)
    ignore_changes = [
      password,  # El password puede cambiar fuera de Terraform
    ]
  }
}

# ===============================================
# RDS MySQL - Chile
# ===============================================

resource "aws_db_instance" "chile" {
  identifier     = "${local.name_prefix}-rds-cl"
  engine         = "mysql"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.rds_cl_database_name
  username = var.rds_cl_master_username
  password = var.rds_cl_master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  multi_az               = var.rds_multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
  deletion_protection    = var.environment == "prod"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-rds-cl"
      Country = "CL"
    }
  )

  # Timeouts para operaciones de RDS
  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }

  # Lifecycle para evitar modificaciones cuando la instancia no está disponible
  lifecycle {
    create_before_destroy = false
    # Ignorar cambios en password después de la creación inicial
    # (para evitar actualizaciones no deseadas después de importar)
    ignore_changes = [
      password,  # El password puede cambiar fuera de Terraform
    ]
  }
}

# ===============================================
# SNS Topics
# ===============================================

resource "aws_sns_topic" "peru" {
  name = "${local.name_prefix}-peru"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-peru"
      Country = "PE"
    }
  )
}

resource "aws_sns_topic" "chile" {
  name = "${local.name_prefix}-chile"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-chile"
      Country = "CL"
    }
  )
}

# ===============================================
# SQS Queues
# ===============================================

resource "aws_sqs_queue" "peru" {
  name                      = "${local.name_prefix}-peru-queue"
  message_retention_seconds = 1209600 # 14 days
  visibility_timeout_seconds = 300

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-peru-queue"
      Country = "PE"
    }
  )
}

resource "aws_sqs_queue" "peru_dlq" {
  name                      = "${local.name_prefix}-peru-queue-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-peru-queue-dlq"
    }
  )
}

resource "aws_sqs_queue" "chile" {
  name                      = "${local.name_prefix}-chile-queue"
  message_retention_seconds = 1209600 # 14 days
  visibility_timeout_seconds = 300

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-chile-queue"
      Country = "CL"
    }
  )
}

resource "aws_sqs_queue" "chile_dlq" {
  name                      = "${local.name_prefix}-chile-queue-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-chile-queue-dlq"
    }
  )
}

resource "aws_sqs_queue" "completion" {
  name                      = "${local.name_prefix}-completion-queue"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-completion-queue"
    }
  )
}

# SNS to SQS subscriptions
resource "aws_sns_topic_subscription" "peru" {
  topic_arn = aws_sns_topic.peru.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.peru.arn
}

resource "aws_sns_topic_subscription" "chile" {
  topic_arn = aws_sns_topic.chile.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.chile.arn
}

# SQS Queue Policies for SNS
resource "aws_sqs_queue_policy" "peru" {
  queue_url = aws_sqs_queue.peru.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.peru.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.peru.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "chile" {
  queue_url = aws_sqs_queue.chile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.chile.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.chile.arn
          }
        }
      }
    ]
  })
}

# ===============================================
# EventBridge
# ===============================================

resource "aws_cloudwatch_event_bus" "main" {
  name = "${local.name_prefix}-bus"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bus"
    }
  )
}

resource "aws_cloudwatch_event_rule" "completion" {
  name        = "${local.name_prefix}-completion-rule"
  description = "Rule for appointment completion events"

  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["agendamiento.citas"]
    detail-type = ["AppointmentCompleted"]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-completion-rule"
    }
  )
}

resource "aws_cloudwatch_event_target" "completion" {
  rule      = aws_cloudwatch_event_rule.completion.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.completion.arn
  event_bus_name = aws_cloudwatch_event_bus.main.name
}

resource "aws_sqs_queue_policy" "completion" {
  queue_url = aws_sqs_queue.completion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.completion.arn
      }
    ]
  })
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
    host     = aws_db_instance.peru.endpoint
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
    host     = aws_db_instance.chile.endpoint
    port     = 3306
    database = var.rds_cl_database_name
    username = var.rds_cl_master_username
    password = var.rds_cl_master_password
  })
}
