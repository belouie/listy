# Setup iam role for lambda
# Setup lambda function to interact with dynamodb
# Setup cloudwatch logs for lambda

resource "aws_iam_role" "listy_lambda" {
  name = "listy_lambda"

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
  tags = local.tags
}

# zip up files for lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/listy_crud/listy_crud"
  output_path = "../lambda/archive/listy_crud.zip"
}

# TODO: create single lambda function for each route/api endpoint
resource "aws_lambda_function" "listy_CRUD_function" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.name
  role          = aws_iam_role.listy_lambda.arn
  handler       = "listy_crud"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = "go1.x"

  memory_size       = 1024
  timeout           = 30

  tags = local.tags 
}

// Logs Policy
data "aws_iam_policy_document" "logs" {
  policy_id = "${local.name}-lambda-logs"
  version   = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.name}*:*"
    ]
  }
}

resource "aws_iam_policy" "logs" {
  name   = "${local.name}-lambda-logs"
  policy = data.aws_iam_policy_document.logs.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  depends_on  = [aws_iam_role.listy_lambda, aws_iam_policy.logs]
  role        = aws_iam_role.listy_lambda.name
  policy_arn  = aws_iam_policy.logs.arn
}

/*
* Cloudwatch
*/

// Log group
resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 7
  tags = local.tags
}