variable "aws_backend_bucket" {
  type = string
  description = "AWS Backend Bucket"
}

variable "aws_backend_key" {
  type = string
  description = "AWS Backend key"
}

variable "aws_region" {
  type = string
  description = "AWS Region"
  default = "us-east-1"
}