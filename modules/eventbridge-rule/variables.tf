variable "name" {
  type        = string
  description = "EventBridge rule name (used also in role and invoke permission names)."
}

variable "description" {
  type        = string
  description = "EventBridge rule description."
}

variable "event_pattern" {
  type = object({
    source      = list(string)
    detail-type = list(string)
    detail = object({
      eventSource = list(string)
      eventName   = list(string)
    })
  })
  description = "EventBridge rule event pattern."
}

variable "event_target_lambda_arn" {
  type        = string
  description = "ARN of the event target Lambda function."
}

variable "event_target_lambda_name" {
  type        = string
  description = "Name of the event target lambda function."
}