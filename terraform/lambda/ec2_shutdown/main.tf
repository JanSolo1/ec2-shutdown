//Lambda function from zip file
resource "aws_lambda_function" "scheduled_updater_function" {          
    function_name = "${var.lambda_name}_${var.stage}"          
    source_code_hash = filebase64sha256("${var.lambda_name}.zip")       
    timeout = 600
    filename = "${var.lambda_name}.zip"                                
    handler = "${var.lambda_name}.main"                               
    role    = aws_iam_role.iam_lambdaRole.arn
    runtime = "python3.9"

    depends_on = [aws_iam_policy.dynamodb_policy, aws_cloudwatch_log_group.log_group]

    environment {
      variables = {
        STAGE = var.stage
        EC2_ID = var.ec2_id
        REGION = var.account.region
      }
    }
    tags = var.tags
}

// Event bridge schedule
resource "aws_cloudwatch_event_rule" "schedule" {
    name = "${var.lambda_name}_${var.stage}-schedule"
    description = "Schedule for ${var.lambda_name}_${var.stage} Lambda Function"
    schedule_expression = "cron(0 20 * * ? *)" # UTC time I think, IDK     
    tags = var.tags
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
    rule = aws_cloudwatch_event_rule.schedule.name
    target_id = "scheduled_updater_function"
    arn = aws_lambda_function.scheduled_updater_function.arn
}

//Logging
resource "aws_cloudwatch_log_group" "log_group" {
    name = "/aws/lambda/${var.stage}/${var.lambda_name}"
    retention_in_days = 14
}

// IAM 
resource "aws_iam_role" "iam_lambdaRole" {
    name = "iam_role_lambda_${var.lambda_name}_${var.stage}"
    assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
    }
    EOF
    tags = var.tags
}

resource "aws_iam_policy" "ec2_policy" {
  name   = "${var.lambda_name}_${var.stage}-ec2-policy"
  description = "Policy for Lambda function to stop EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:DescribeInstanceStatus",
          "ec2:StopInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.iam_lambdaRole.id
  policy_arn = aws_iam_policy.ec2_policy.arn
}


resource "aws_iam_policy" "dynamodb_policy" {
    name   = "${var.lambda_name}_${var.stage}-dynamodb-policy"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ], 
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "cloudwatch:GetInsightRuleReport",
            "Effect": "Allow",
            "Resource": "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
        }
    ]
})
}


resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.iam_lambdaRole.id
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

//For invoking function using Cloudwatch trigger
resource "aws_lambda_permission" "allow_cloudwatch" {
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = "${var.lambda_name}_${var.stage}"  
    principal     = "events.amazonaws.com"
}

resource "aws_lambda_permission" "allow_eventbridge" {
    statement_id  = "AllowExecutionFromEventBridge"
    action        = "lambda:InvokeFunction"
    function_name = "${var.lambda_name}_${var.stage}"  
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.schedule.arn
}