data "archive_file" "this" {
  type        = "zip"
  source_file = var.lambda_func.source_file
  output_path = "${trimsuffix(var.lambda_func.source_file, ".py")}.zip"
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = var.lambda_func.function_name
  role          = var.lambda_func.role
  handler       = var.lambda_func.handler
  code_sha256   = data.archive_file.this.output_base64sha256
  runtime       = var.lambda_func.runtime
}
