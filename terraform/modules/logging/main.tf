variable "name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "siem_firehose_arn" {
  description = "Firehose stream that delivers to the OHIP SIEM."
  type        = string
}

variable "log_group_names" {
  description = "Log groups to create; every one is forwarded to the SIEM."
  type        = list(string)
}

variable "retention_days" {
  type    = number
  default = 400
}

resource "aws_cloudwatch_log_group" "this" {
  for_each          = toset(var.log_group_names)
  name              = each.value
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_arn
}

# Forward every log group to the OHIP SIEM (INFRA logging standard).
resource "aws_cloudwatch_log_subscription_filter" "siem" {
  for_each        = aws_cloudwatch_log_group.this
  name            = "${var.name}-to-siem"
  log_group_name  = each.value.name
  filter_pattern  = ""
  destination_arn = var.siem_firehose_arn
  role_arn        = aws_iam_role.cwl_to_firehose.arn
}

resource "aws_iam_role" "cwl_to_firehose" {
  name = "${var.name}-cwl-to-siem"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cwl_to_firehose" {
  name = "put-to-siem-stream"
  role = aws_iam_role.cwl_to_firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
      Resource = var.siem_firehose_arn
    }]
  })
}

output "log_group_arns" {
  value = [for g in aws_cloudwatch_log_group.this : g.arn]
}
