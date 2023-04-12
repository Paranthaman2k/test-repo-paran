
provider "aws" {

    access_key = "AKIA25437MY3OUDUN5GW"
    secret_key = "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"
    region = "us-east-1"
}

# Define the SNS topic for CloudTrail notifications
resource "aws_sns_topic" "cloudtrail_topic" {
  name = "cloudtrail-notifications"
}

# Define the SNS topic subscription for email notifications
resource "aws_sns_topic_subscription" "cloudtrail_email_subscription" {
  topic_arn = aws_sns_topic.cloudtrail_topic.arn
  protocol  = "email"
  endpoint  = "paranthamanaws1@gmail.com"
}

# Define the CloudTrail trail to capture events
resource "aws_cloudtrail" "my_trail" {
  name                          = "my-trail"
  s3_bucket_name                = "mybuck09032023"
  sns_topic_name                = aws_sns_topic.cloudtrail_topic.name
  include_global_service_events = true
}

resource "aws_s3_bucket_policy" "my_trail" {
  bucket = "mybuck09032023"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::mybuck09032023/*",
      "Condition": {
         "IpAddress": {"aws:SourceIp": "8.8.8.8/32"}
      }
    }
  ]
}
POLICY
}


# Define the CloudWatch Logs filter to trigger the SNS notification
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_filter" {
  name           = "cloudtrail-filter"
  pattern        = "{ ($.eventName = CreateBucket*) || ($.eventName = DeleteBucket*) }"
  log_group_name = "${aws_cloudtrail.my_trail.arn}"

  metric_transformation {
    name      = "cloudtrail-metric"
    namespace = "AWS/CloudTrail"
    value     = "1"
  }
}

# Define the CloudWatch alarm to monitor the CloudWatch Logs metric
resource "aws_cloudwatch_metric_alarm" "cloudtrail_alarm" {
  alarm_name          = "cloudtrail-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "cloudtrail-metric"
  namespace           = "AWS/CloudTrail"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"

  alarm_description = "This metric checks for CloudTrail events that create or delete S3 buckets"

  alarm_actions = [
    aws_sns_topic.cloudtrail_topic.arn,
  ]
}
