environment           = "prod"
application_id        = "OHIP-APP-0417"
cost_center           = "CC-MES-2210"
vpc_id                = "vpc-0a1b2c3d4e5f60718"
private_subnet_ids    = ["subnet-0aa11bb22cc33dd44", "subnet-0ee55ff66aa77bb88"]
app_security_group_id = "sg-0123456789abcdef0"
siem_firehose_arn     = "arn:aws:firehose:us-east-1:111122223333:deliverystream/ohip-siem-ingest"

snowflake_integration_role_arn = "arn:aws:iam::111122223333:role/nea-prod-snowflake-integration"
