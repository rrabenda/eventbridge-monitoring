# Security events monitoring with EventBride

Serverless solution to monitor security-related events in AWS using EventBridge, a Python Lambda function, and SNS. Currently, it monitors four events:
- IAM user creation,
- IAM user access key creation,
- S3 bucket policy change,
- Security group ingress changes (create, remove, update). Event for ingress and egress updates is the same (`ModifySecurityGroupRules`), so it will be also triggered for engress updates.

EventBridge will trigger Lambda function, which will send proper notification to SNS topic and, from there, to the recipient via email.

### Deployment and testing

Solution is using local state. To leverage remote state please update the `env/backend.tfvars` file with proper values and modify the state definition in the `backend.tf` file.

The `sns_topic_email_endpoint` value is not defined in the variables file, please update it with proper email address. Next solution can be deployed with `terraform plan -var-file="env/env.tfvars"` and `terraform apply -var-file="env/env.tfvars"` commands.

To test solution, Approve a subscription from the SNS topic and perform one of monitored actions.

### Limitations

- Trail events return non-standardized output for different events, so the Lambda function can only process JSONs corresponding to the four events defined above.
- To avoid duplicating Python code, EventBridge rules reuse the same Lambda.
- The monitoring solution has been tested only in one region, but it can be easily expanded to all regions using the `is_multi_region_trail` in the `aws_cloudtrail` resource.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.91.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_evenbridge_rule"></a> [evenbridge\_rule](#module\_evenbridge\_rule) | ./modules/eventbridge-rule | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.security_events_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.security_incident_notifications_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.security_notifications_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.security_notifications_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.security_incident_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.claudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.claudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.claudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sns_topic.security_events_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.user_updates_sqs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [random_string.bucket_name_extension](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [archive_file.lambda_code](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.claudtrail_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.security_notifications_lambda_assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.security_notifications_lambda_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudtrail_enable_logging"></a> [cloudtrail\_enable\_logging](#input\_cloudtrail\_enable\_logging) | Enable trail logging. | `bool` | `true` | no |
| <a name="input_cloudtrail_event_type_logging"></a> [cloudtrail\_event\_type\_logging](#input\_cloudtrail\_event\_type\_logging) | Type of events to log. Valid values are ReadOnly, WriteOnly, All. | `string` | `"All"` | no |
| <a name="input_cloudtrail_exclude_management_events"></a> [cloudtrail\_exclude\_management\_events](#input\_cloudtrail\_exclude\_management\_events) | A set of event sources to exclude. Valid values include: kms.amazonaws.com and rdsdata.amazonaws.com. | `set(string)` | `null` | no |
| <a name="input_cloudtrail_include_global_services"></a> [cloudtrail\_include\_global\_services](#input\_cloudtrail\_include\_global\_services) | Include events from global services such as IAM in the log files. | `bool` | `false` | no |
| <a name="input_eventbridge_rules"></a> [eventbridge\_rules](#input\_eventbridge\_rules) | Map of all EventBridge rules. | <pre>map(object({<br/>    name        = string<br/>    description = string<br/>    event_pattern = object({<br/>      source      = list(string)<br/>      detail-type = list(string)<br/>      detail = object({<br/>        eventSource = list(string)<br/>        eventName   = list(string)<br/>      })<br/>    })<br/>    event_target_lambda_arn  = optional(string)<br/>    event_target_lambda_name = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_log_retention"></a> [log\_retention](#input\_log\_retention) | Number of days the logs will be retained (S3 and CloudWatch). | `number` | `30` | no |
| <a name="input_notification_lambda_function_name"></a> [notification\_lambda\_function\_name](#input\_notification\_lambda\_function\_name) | Security notification Lambda function name. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources. | `string` | n/a | yes |
| <a name="input_sns_topic_email_endpoint"></a> [sns\_topic\_email\_endpoint](#input\_sns\_topic\_email\_endpoint) | Target email for SNS notifications. | `string` | n/a | yes |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | SNS topic name. | `string` | n/a | yes |
| <a name="input_trail_name"></a> [trail\_name](#input\_trail\_name) | CloudTrail trail name. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->