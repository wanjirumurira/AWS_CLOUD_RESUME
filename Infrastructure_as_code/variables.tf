variable "profile" {
    description = "AWS Profile"
    type = string
  
}
variable "aws_region"{
    description = "AWS Region"
    type = string
}
variable "bucket_name" { 
    description = "Name of the Bucket"
    type = string
}

variable "DynamoDB_table" {
    description = "My DynamoDB Table"
    type = string
}