resource "aws_cloudwatch_event_rule" "this" {
  name        = var.name
  description = var.description
  role_arn    = aws_iam_role.this.arn

  event_pattern = jsonencode({
    source      = var.event_pattern["source"]
    detail-type = var.event_pattern["detail-type"]
    detail = {
      eventSource = var.event_pattern["detail"]["eventSource"]
      eventName   = var.event_pattern["detail"]["eventName"]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "SendToLambda"
  arn       = var.event_target_lambda_arn
}

resource "aws_lambda_permission" "this" {
  statement_id  = "${var.name}_allow_execution"
  action        = "lambda:InvokeFunction"
  function_name = var.event_target_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

resource "aws_iam_role" "this" {
  name               = "${var.name}_rule_role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
