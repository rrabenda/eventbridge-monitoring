# CloudTrail

resource "aws_cloudtrail" "security_events_monitoring" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.claudtrail_logs.id
  include_global_service_events = var.cloudtrail_include_global_services
  enable_logging                = var.cloudtrail_enable_logging

  event_selector {
    read_write_type           = var.cloudtrail_event_type_logging
    include_management_events = true
    # There is a possibility to exclude events only from RDS and KMS services; 
    # variable naming with above include_management_events can be misleading.
    exclude_management_event_sources = var.cloudtrail_exclude_management_events

  }

  depends_on = [aws_s3_bucket_policy.claudtrail_logs]
}

resource "aws_s3_bucket" "claudtrail_logs" {
  bucket        = "cloudtrail-logs-${var.region}-${random_string.bucket_name_extension.result}"
  force_destroy = true
}

resource "random_string" "bucket_name_extension" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "claudtrail_logs" {
  bucket = aws_s3_bucket.claudtrail_logs.id
  policy = data.aws_iam_policy_document.claudtrail_logs_bucket.json
}

resource "aws_s3_bucket_lifecycle_configuration" "claudtrail_logs" {
  bucket = aws_s3_bucket.claudtrail_logs.id

  rule {
    id = "RemoveOldLogs"

    expiration {
      days = var.log_retention
    }

    status = "Enabled"
  }
}

# EventBridge rules

module "evenbridge_rule" {
  source = "./modules/eventbridge-rule"

  for_each = var.eventbridge_rules

  name                     = each.value.name
  description              = each.value.description
  event_pattern            = each.value.event_pattern
  event_target_lambda_name = var.notification_lambda_function_name
  event_target_lambda_arn  = aws_lambda_function.security_incident_notifications.arn
}

# Lambda

resource "aws_lambda_function" "security_incident_notifications" {
  filename      = data.archive_file.lambda_code.output_path
  function_name = var.notification_lambda_function_name
  role          = aws_iam_role.security_notifications_lambda.arn
  handler       = "main.handler"
  timeout       = 10
  runtime       = "python3.13"

  environment {
    variables = {
      sns_topic_arn = aws_sns_topic.security_events_notification.arn
    }
  }

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  depends_on = [
    aws_iam_role_policy.security_notifications_lambda,
    aws_sns_topic.security_events_notification
  ]
}

resource "aws_iam_role" "security_notifications_lambda" {
  name               = "SecurityNotificationLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.security_notifications_lambda_assume_policy.json
}

resource "aws_iam_role_policy" "security_notifications_lambda" {
  name   = "SecurityNotificationLambdaExecutionPolicy"
  role   = aws_iam_role.security_notifications_lambda.id
  policy = data.aws_iam_policy_document.security_notifications_lambda_execution.json
}

resource "aws_cloudwatch_log_group" "security_incident_notifications_logs" {
  name              = "/aws/lambda/${var.notification_lambda_function_name}"
  retention_in_days = var.log_retention
}

# SNS

resource "aws_sns_topic" "security_events_notification" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.security_events_notification.arn
  protocol  = "email"
  endpoint  = var.sns_topic_email_endpoint
}