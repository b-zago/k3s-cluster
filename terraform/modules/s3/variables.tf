variable "bucket_name" {
  type        = string
  description = "Bucket name"
}

variable "bucket_tags" {
  type = object({
    Project = string
  })
  description = "Tags for the bucket to identify which project it belong to"
}

