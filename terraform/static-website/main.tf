module "static_website_bucket" {
  source      = "../modules/s3"
  bucket_name = "${var.project_name}-bucket"
  bucket_tags = { Project = "static_website" }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = module.static_website_bucket.bucket_id

  index_document {
    suffix = var.suffix
  }
}

resource "aws_s3_object" "website" {
  bucket       = module.static_website_bucket.bucket_id
  key          = "index.html"
  source       = "./website/index.html"
  content_type = "text/html"

  etag = filemd5("./website/index.html")
}
