output "s3_url" {
  value       = "http://${aws_s3_bucket.my-bucket.bucket}.s3-website-${var.region}.amazonaws.com"
  description = "The URL to access the S3 bucket website"
}

output "dist_url" {
  description = "Website URL (HTTPS)"
  value       = aws_cloudfront_distribution.cf_dist.domain_name
}

output "api_url" {
  value = aws_api_gateway_deployment.visitor_deployment.invoke_url
}
