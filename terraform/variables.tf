# ===============================================
# Variables - Terraform
# ===============================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "agendamiento-citas"
}

# ===============================================
# VPC Variables
# ===============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ===============================================
# RDS Variables
# ===============================================

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Free tier
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false  # true for production
}

# RDS Peru
variable "rds_pe_database_name" {
  description = "Database name for Peru"
  type        = string
  default     = "appointments_pe"
}

variable "rds_pe_master_username" {
  description = "Master username for Peru RDS"
  type        = string
  sensitive   = true
}

variable "rds_pe_master_password" {
  description = "Master password for Peru RDS"
  type        = string
  sensitive   = true
}

# RDS Chile
variable "rds_cl_database_name" {
  description = "Database name for Chile"
  type        = string
  default     = "appointments_cl"
}

variable "rds_cl_master_username" {
  description = "Master username for Chile RDS"
  type        = string
  sensitive   = true
}

variable "rds_cl_master_password" {
  description = "Master password for Chile RDS"
  type        = string
  sensitive   = true
}

