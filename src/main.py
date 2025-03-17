import os
import logging
import boto3

# Set up the logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize the SNS Client
sns_client = boto3.client('sns')

# Initialize lambda variables
sns_topic_arn = os.environ['sns_topic_arn']

def process_event(event):
  """Helper function to process CloudTrail event"""
  try:
    time = event['detail']['eventTime']
    initiator = event['detail']['userIdentity']['userName']
    event_action = event['detail']['eventName']
    if event_action == 'CreateUser':
      action = 'User Created'
      resource = event['detail']['responseElements']['user']['arn']
    elif event_action == 'CreateAccessKey':
      action = 'User Access Key Created'
      resource = ('AccessKey ' + event['detail']['responseElements']['accessKey']['accessKeyId'] +
                  ' for ' + event['detail']['responseElements']['accessKey']['userName'])
    elif event_action == 'PutBucketPolicy':
      action = 'Bucket Policy Changed'
      resource = 'arn:aws:s3:::' + event['detail']['requestParameters']['bucketName']
    elif event_action == 'ModifySecurityGroupRules':
      action = 'Security Group Rule Changed'
      resource = ('Security group with ID' +
                event['detail']['requestParameters']['ModifySecurityGroupRulesRequest']['GroupId'] +
                ' in ' + event['detail']['awsRegion'] + ' region')
    elif event_action in ['AuthorizeSecurityGroupIngress', 'RevokeSecurityGroupIngress']:
      action = 'Security Group Ingress Changed'
      resource = ('Security group with ID: ' + event['detail']['requestParameters']['groupId'] +
                  ' in ' + event['detail']['awsRegion'] + ' region')
    else:
      logger.debug('Failing event: %s', event)
      raise ValueError('Not supported eventName')

    return time, initiator, action, resource

  except Exception as e:
    logger.error('Failed to process event: %s', e)
    raise

def generate_notification(time, initiator, action, resource):
  """Helper function to generate subject and message for SNS topic"""
  try:
    subject = 'AWS security event notification: ' + action
    message = ('Action: ' + action + ',\n' +
                'By: ' + initiator + ',\n' +
                'On: ' + resource + ',\n' +
                'At: ' + time + '.')

    return subject, message

  except Exception as e:
    logger.error('Failed to generate notification: %s', e)
    raise

def send_sns_notification(topic_arn, subject, message):
  """Helper function to send SNS nofitication"""
  try:
    sns_client.publish(
      TopicArn=topic_arn,
      Subject=subject,
      Message=message,
    )
  except Exception as e:
    logger.error('Failed to send SNS notification: %s', e)
    raise

def handler(event, context):
  """
    Main Lambda handler function
    Parameters:
        event: Dict containing the Lambda function event data
        context: Lambda runtime context
    """
  try:
    time, initiator, action, resource = process_event(event)

    subject, message = generate_notification(time, initiator, action, resource)

    send_sns_notification(sns_topic_arn, subject, message)

  except Exception as e:
    logger.error('Lambda execution failed: %s', e)
    raise
