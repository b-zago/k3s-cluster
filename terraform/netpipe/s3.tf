resource "aws_s3_bucket" "s3_bucket" {
  bucket = "netpipe-bucket"
}

resource "aws_s3_bucket_public_access_block" "s3_pab" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  rule {
    id     = "netpipe_expire_all_1day"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
