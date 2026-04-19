variable "project_name" {
  type    = string
  default = "static-website"
}

variable "suffix" {
  type        = string
  default     = "index.html"
  description = "Optional aws_s3_bucket_website_configuration for a bucket"
}
