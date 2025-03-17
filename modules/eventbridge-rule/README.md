<!-- BEGIN_TF_DOCS -->
# EventBridge Rule Terraform Module

This Terraform module create rule in AWS EventBridge with a Lambda function as a target. The module creates only the rule, with the required configuration and permissions to invoke the Lambda function. The function name and ARN must be provided as input parameters.

## Usage

```hcl
module "demo" {
  source = "./modules/eventbridge-rule"

  name                     = "test_name"
  description              = "description"
  event_pattern            = {
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName   = ["CreateUser"]
    }
  }
  event_target_lambda_name = "lambda_function_name"
  event_target_lambda_arn  = "lambda_function_arn"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |


## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | EventBridge rule description. | `string` | n/a | yes |
| <a name="input_event_pattern"></a> [event\_pattern](#input\_event\_pattern) | EventBridge rule event pattern. | <pre>object({<br/>    source      = list(string)<br/>    detail-type = list(string)<br/>    detail = object({<br/>      eventSource = list(string)<br/>      eventName   = list(string)<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_event_target_lambda_arn"></a> [event\_target\_lambda\_arn](#input\_event\_target\_lambda\_arn) | ARN of the event target Lambda function. | `string` | n/a | yes |
| <a name="input_event_target_lambda_name"></a> [event\_target\_lambda\_name](#input\_event\_target\_lambda\_name) | Name of the event target lambda function. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | EventBridge rule name (used also in role and invoke permission names). | `string` | n/a | yes |

<!-- END_TF_DOCS -->