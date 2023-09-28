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

