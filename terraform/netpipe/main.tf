#check permissions on lambda_core it actually needs a role for s3 + cloudwatch
module "lambda_authorizer" {
  source = "../modules/lambda"
  lambda_func = {
    function_name = "netpipe_authorizer"
    handler       = "lambda_auth.lambda_handler"
    runtime       = "python3.14"
    source_file   = "./lambda/lambda_auth.py"
    role          = aws_iam_role.lambda_authorizer_iam_role.arn
  }
}

module "lambda_core" {
  source = "../modules/lambda"
  lambda_func = {
    function_name = "netpipe_core"
    handler       = "lambda_core.lambda_handler"
    runtime       = "python3.14"
    source_file   = "./lambda/lambda_core.py"
    role          = aws_iam_role.lambda_core_iam_role.arn
  }
}


resource "aws_lambda_permission" "lambda_auth_permission" {
  statement_id  = "AllowGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_authorizer.lambda_data.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gateway_http_api.execution_arn}/*"
}

resource "aws_lambda_permission" "lambda_core_permission" {
  statement_id  = "AllowGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_core.lambda_data.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gateway_http_api.execution_arn}/*"
}


output "api_endpoint" {
  value = "http://${aws_apigatewayv2_api.gateway_http_api.id}.execute-api.localhost.localstack.cloud:4566/${aws_apigatewayv2_stage.api_stage.name}/test"
}
