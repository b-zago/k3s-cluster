data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_authorizer_access_dynamodb" {
  statement {
    effect = "Allow"

    actions   = ["dynamodb:GetItem"]
    resources = ["${aws_dynamodb_table.dynamodb_table.arn}"]
  }
}

resource "aws_iam_policy" "lambda_authorizer_dynamodb_policy" {
  name   = "netpipe_lambda_authorizer_dynamodb_policy"
  policy = data.aws_iam_policy_document.lambda_authorizer_access_dynamodb.json
}

resource "aws_iam_role" "lambda_authorizer_iam_role" {
  name               = "netpipe_lambda_authorizer_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_dynamodb_attachment" {
  role       = aws_iam_role.lambda_authorizer_iam_role.name
  policy_arn = aws_iam_policy.lambda_authorizer_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_logs_attachment" {
  role       = aws_iam_role.lambda_authorizer_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###---LAMBDA-CORE---###

data "aws_iam_policy_document" "lambda_core_access_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}"]
  }
}

resource "aws_iam_role" "lambda_core_iam_role" {
  name               = "netpipe_lambda_core_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_core_s3_policy" {
  name   = "netpipe_lambda_core_s3_policy"
  policy = data.aws_iam_policy_document.lambda_core_access_s3.json
}

resource "aws_iam_role_policy_attachment" "lambda_core_s3_attachment" {
  role       = aws_iam_role.lambda_core_iam_role.name
  policy_arn = aws_iam_policy.lambda_core_s3_policy.arn
}
