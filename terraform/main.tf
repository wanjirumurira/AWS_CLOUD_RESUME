terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "my-bucket" {
  bucket = "my-bucket-resume-test2"
  tags = {
    Name = "resume"
  }
}


resource "aws_s3_object" "object" {
  bucket       = aws_s3_bucket.my-bucket.id
  for_each     = fileset("../FrontEnd/", "*")
  key          = each.value
  source       = "../FrontEnd/${each.value}"
  etag         = filemd5("../FrontEnd/${each.value}")
  content_type = "text/html"
  depends_on = [
    aws_s3_bucket.my-bucket
  ]
}

resource "aws_s3_bucket_website_configuration" "my-bucket" {
  bucket = aws_s3_bucket.my-bucket.id

  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_bucket_policy" "restrict_modify_access" {
  bucket = aws_s3_bucket.my-bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": [
        "${aws_s3_bucket.my-bucket.arn}",
        "${aws_s3_bucket.my-bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

