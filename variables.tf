variable "region" {
  type        = string
  description = "AWS region to deploy resources."
}

variable "trail_name" {
  type        = string
  description = "CloudTrail trail name."
}

variable "log_retention" {
  type        = number
  description = "Number of days the logs will be retained (S3 and CloudWatch)."
  default     = 30
}

variable "cloudtrail_enable_logging" {
  type        = bool
  description = "Enable trail logging."
  default     = true
}

variable "cloudtrail_include_global_services" {
  type        = bool
  description = "Include events from global services such as IAM in the log files."
  default     = false
}

variable "cloudtrail_event_type_logging" {
  type        = string
  description = "Type of events to log. Valid values are ReadOnly, WriteOnly, All."
  default     = "All"
  validation {
    condition     = contains(["ReadOnly", "WriteOnly", "All"], var.cloudtrail_event_type_logging)
    error_message = "Valid value is one of the following: ReadOnly, WriteOnly, All."
  }
}

variable "cloudtrail_exclude_management_events" {
  type        = set(string)
  description = "A set of event sources to exclude. Valid values include: kms.amazonaws.com and rdsdata.amazonaws.com."
  default     = null
}

variable "notification_lambda_function_name" {
  type        = string
  description = "Security notification Lambda function name."
}

variable "sns_topic_name" {
  type        = string
  description = "SNS topic name."
}

variable "sns_topic_email_endpoint" {
  type        = string
  description = "Target email for SNS notifications."
}

variable "eventbridge_rules" {
  description = "Map of all EventBridge rules."
  type = map(object({
    name        = string
    description = string
    event_pattern = object({
      source      = list(string)
      detail-type = list(string)
      detail = object({
        eventSource = list(string)
        eventName   = list(string)
      })
    })
    event_target_lambda_arn  = optional(string)
    event_target_lambda_name = optional(string)
  }))
}