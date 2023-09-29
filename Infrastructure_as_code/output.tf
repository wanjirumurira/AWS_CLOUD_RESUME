output "website_url"{
    description = "URL of the website"
    value = "http://${aws_s3_bucket.hosting_bucket.bucket}.s3-website.${var.aws_region}.amazonaws.com"

}

