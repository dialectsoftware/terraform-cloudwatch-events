terraform {
  required_version = "> 0.7.0"
}

provider "aws" {
  version = "~> 1.16"
  region  = "${var.aws_region}"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

#********************* create lambda *********************

resource "aws_iam_role" "iam-for-lambda-broker-role" {
  lifecycle {
    ignore_changes = ["*"]
  }

  name               = "iam-for-lambda-broker-role"
  assume_role_policy = "${file("vpc_lambda_assume_role_policy.json")}"
}

resource "aws_iam_policy" "iam-for-lambda-broker-policy" {
  lifecycle {
    ignore_changes = ["*"]
  }

  name   = "iam-for-lambda-broker-policy"
  policy = "${file("vpc_lambda_broker_policy.json")}"
}

resource "aws_iam_policy_attachment" "iam-for-lambda-broker-attach-policy" {
  lifecycle {
    ignore_changes = ["*"]
  }

  name       = "Lambda_CloudWatchLogs_Role_Attach_Policy"
  roles      = ["${aws_iam_role.iam-for-lambda-broker-role.name}"]
  policy_arn = "${aws_iam_policy.iam-for-lambda-broker-policy.arn}"
}

resource "aws_lambda_function" "lambda_broker" {
  lifecycle {
    ignore_changes = ["*"]
  }

  filename         = "broker.zip"
  function_name    = "lambda_broker_function"
  role             = "${aws_iam_role.iam-for-lambda-broker-role.arn}"
  handler          = "broker.handler"
  source_code_hash = "${base64sha256(file("broker.zip"))}"
  runtime          = "python3.6"

  environment {
    variables = {
      EMAIL_FROM = "${var.email_address}"
      EMAIL_TO   = "${var.email_address}"
    }
  }
}

#********************* configure  cloudwatch *********************
resource "aws_lambda_permission" "allow_cloudwatch" {
  lifecycle {
    ignore_changes = ["*"]
  }

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_broker.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ec2_events.arn}"
}

resource "aws_cloudwatch_event_rule" "ec2_events" {
  name        = "capture-ec2-events"
  description = "Capture each AWS EC2 Event"

  #https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html
  event_pattern = <<PATTERN
{
  "source": [ "aws.ec2" ],
  "detail-type": [ "EC2 Instance State-change Notification" ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  target_id = "lambda_event_target"
  rule      = "${aws_cloudwatch_event_rule.ec2_events.name}"
  arn       = "${aws_lambda_function.lambda_broker.arn}"
}
