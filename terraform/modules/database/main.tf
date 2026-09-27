variable "name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "Aurora access from NEA ingest workers only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ingest workers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }
}

# TLS required for every connection.
resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name}-pg16"
  family = "aurora-postgresql16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier                  = var.name
  engine                              = "aurora-postgresql"
  engine_version                      = "16.4"
  database_name                       = "nea"
  master_username                     = "nea_admin"
  manage_master_user_password         = true # break-glass only; stored in Secrets Manager
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_arn
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.db.id]
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.this.name
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  backup_retention_period             = 35
  deletion_protection                 = true
  copy_tags_to_snapshot               = true
  final_snapshot_identifier           = "${var.name}-final"
}

resource "aws_rds_cluster_instance" "this" {
  count                           = 2
  identifier                      = "${var.name}-${count.index}"
  cluster_identifier              = aws_rds_cluster.this.id
  instance_class                  = "db.r6g.large"
  engine                          = aws_rds_cluster.this.engine
  publicly_accessible             = false
  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn
}

output "endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "cluster_resource_id" {
  value = aws_rds_cluster.this.cluster_resource_id
}
