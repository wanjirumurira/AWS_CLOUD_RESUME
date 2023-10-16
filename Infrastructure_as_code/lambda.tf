resource "aws_iam_role" "iam_for_lambda" {
  assume_role_policy  = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "",
          }
        ]
      })

      }

resource "aws_iam_role_policy" "dynamodb_lambda_policy" {
  name   = "lambda-dynamodb-policy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource": "${aws_dynamodb_table.visitor_table.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        #"Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
        "Resource": "arn:aws:logs:*:*:*"
      },
      {
        "Effect": "Allow",
        "Action": "logs:CreateLogGroup",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_lambda_function" "visitor_function" {
  function_name = "lambda_function"
  filename         = "my_lambda_function.zip"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("my_lambda_function.zip")
}


# Permission, API Gateway can invoke Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.visitor_apigw.execution_arn}/*/*"
}


