module "canary_test_v1" {
  source        = "../../modules/lambda/zip"
  function_name = "canary_test_v1"
  role_arn      = aws_iam_role.canary_test_lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
}

resource "aws_lambda_function" "canary_test_v2" {
  function_name = "canary_test_v2"
  role          = aws_iam_role.canary_test_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.canary_test.repository_url}:latest"

  lifecycle {
    ignore_changes = [
      image_uri,
      environment,
    ]
  }
}
resource "aws_lambda_permission" "apigw_v1" {
  action        = "lambda:InvokeFunction"
  function_name = module.canary_test_v1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.canary_test.execution_arn}/*/${aws_api_gateway_method.v1_get.http_method}${aws_api_gateway_resource.v1.path}"
}

resource "aws_lambda_permission" "apigw_v2" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.canary_test_v2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.canary_test.execution_arn}/*/${aws_api_gateway_method.v2_get.http_method}${aws_api_gateway_resource.v2.path}"
}

resource "aws_lambda_permission" "apigw_canary_v1" {
  action        = "lambda:InvokeFunction"
  function_name = module.canary_test_v1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.canary_test.execution_arn}/*/GET/canary"
}

resource "aws_lambda_permission" "apigw_canary_v2" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.canary_test_v2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.canary_test.execution_arn}/*/GET/canary"
}
