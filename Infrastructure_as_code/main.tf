locals {
  content_types = {
    ".html" : "text/html",
    ".css" : "text/css"
  }
}

provider "aws" {
    region = var.aws_region
    profile = var.profile
}

resource "aws_s3_bucket" "hosting_bucket"{
    bucket = var.bucket_name
    
   
}

resource "aws_s3_bucket_public_access_block" "my-static-website" {
  bucket = aws_s3_bucket.hosting_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.hosting_bucket.id
    
    policy = jsonencode({
        
    "Version": "2012-10-17",
    "Statement": [
        {      
            "Sid": "PublicReadGetObject",    
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.hosting_bucket.id}/*"                
        }
    ]
    })
  
}

resource "aws_s3_object" "file" {
  for_each     = fileset(path.module, "templates/**/*.{html,css}")
  bucket       = aws_s3_bucket.hosting_bucket.id
  key          = replace(each.value, "/^templates//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  etag         = filemd5(each.value)
}

resource "aws_s3_bucket_website_configuration" "my_resume_website" {
     bucket = aws_s3_bucket.hosting_bucket.id
     index_document {
       suffix = "intro.html"
     }
  
 }

resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket_website_configuration.my_resume_website.website_endpoint
    origin_id   = aws_s3_bucket.hosting_bucket.bucket_regional_domain_name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.hosting_bucket.bucket_regional_domain_name
  }
}

resource "aws_dynamodb_table" "visitor_table" {
  name = "visitor_counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key =  "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}

resource "aws_api_gateway_rest_api" "visitor_apigw" {
    name = "visitor_api"
    description = "Visitor API Gateway"
    endpoint_configuration {
      types = ["REGIONAL"]
    } 
}

resource "aws_api_gateway_resource" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  parent_id = aws_api_gateway_rest_api.visitor_apigw.root_resource_id
  path_part = "visitor"
}

resource "aws_api_gateway_method" "getVisitor" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id   = aws_api_gateway_resource.visitor.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "lambda_function"
  filename         = data.archive_file.lambda_zip_file.output_path
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  handler          = "lambda_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.10"
}



data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "../lambda_function/lambda_function.py"  # Relative path to Lambda function code
  output_path = "${path.module}/my_lambda_function.zip"
}


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

