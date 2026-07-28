resource "aws_api_gateway_rest_api" "canary_test" {
  name = "canary_test"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "canary_test" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.v1_get,
      aws_api_gateway_integration.v1,
      aws_api_gateway_method_response.v1_get_200,
      aws_api_gateway_integration_response.v1_get_200,
      aws_api_gateway_method.v2_get,
      aws_api_gateway_integration.v2,
      aws_api_gateway_method_response.v2_get_200,
      aws_api_gateway_integration_response.v2_get_200,
      aws_api_gateway_method.canary_get,
      aws_api_gateway_integration.canary,
      aws_api_gateway_method_response.canary_get_200,
      aws_api_gateway_integration_response.canary_get_200,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "test" {
  deployment_id = aws_api_gateway_deployment.canary_test.id
  rest_api_id   = aws_api_gateway_rest_api.canary_test.id
  stage_name    = "test"
}

resource "aws_api_gateway_stage" "canary_test" {
  deployment_id = aws_api_gateway_deployment.canary_test.id
  rest_api_id   = aws_api_gateway_rest_api.canary_test.id
  stage_name    = "canary_test"

  variables = {
    functionName = module.canary_test_v1.function_name
  }

  canary_settings {
    percent_traffic = 50
    deployment_id   = aws_api_gateway_deployment.canary_test.id
    stage_variable_overrides = {
      functionName = aws_lambda_function.canary_test_v2.function_name
    }
  }
}

# canary (50% v1 / 50% v2 via stage variable routing)

resource "aws_api_gateway_resource" "canary" {
  parent_id   = aws_api_gateway_rest_api.canary_test.root_resource_id
  path_part   = "canary"
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_method" "canary_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.canary.id
  rest_api_id   = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_integration" "canary" {
  rest_api_id             = aws_api_gateway_rest_api.canary_test.id
  resource_id             = aws_api_gateway_resource.canary.id
  http_method             = aws_api_gateway_method.canary_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:${data.aws_caller_identity.self.account_id}:function:$${stageVariables.functionName}/invocations"
}

resource "aws_api_gateway_method_response" "canary_get_200" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.canary.id
  http_method = aws_api_gateway_method.canary_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "canary_get_200" {
  depends_on  = [aws_api_gateway_integration.canary]
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.canary.id
  http_method = aws_api_gateway_method.canary_get.http_method
  status_code = aws_api_gateway_method_response.canary_get_200.status_code
  response_templates = {
    "application/json" = ""
  }
}

# v1

resource "aws_api_gateway_resource" "v1" {
  parent_id   = aws_api_gateway_rest_api.canary_test.root_resource_id
  path_part   = "v1"
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_method" "v1_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.v1.id
  rest_api_id   = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_integration" "v1" {
  rest_api_id             = aws_api_gateway_rest_api.canary_test.id
  resource_id             = aws_api_gateway_resource.v1.id
  http_method             = aws_api_gateway_method.v1_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = module.canary_test_v1.invoke_arn
}

resource "aws_api_gateway_method_response" "v1_get_200" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.v1.id
  http_method = aws_api_gateway_method.v1_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "v1_get_200" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.v1.id
  http_method = aws_api_gateway_method.v1_get.http_method
  status_code = aws_api_gateway_method_response.v1_get_200.status_code
  response_templates = {
    "application/json" = ""
  }
}

# v2

resource "aws_api_gateway_resource" "v2" {
  parent_id   = aws_api_gateway_rest_api.canary_test.root_resource_id
  path_part   = "v2"
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_method" "v2_get" {
  api_key_required = false
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.v2.id
  rest_api_id      = aws_api_gateway_rest_api.canary_test.id
}

resource "aws_api_gateway_integration" "v2" {
  rest_api_id             = aws_api_gateway_rest_api.canary_test.id
  resource_id             = aws_api_gateway_resource.v2.id
  http_method             = aws_api_gateway_method.v2_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = aws_lambda_function.canary_test_v2.invoke_arn
}

resource "aws_api_gateway_method_response" "v2_get_200" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.v2.id
  http_method = aws_api_gateway_method.v2_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "v2_get_200" {
  rest_api_id = aws_api_gateway_rest_api.canary_test.id
  resource_id = aws_api_gateway_resource.v2.id
  http_method = aws_api_gateway_method.v2_get.http_method
  status_code = aws_api_gateway_method_response.v2_get_200.status_code
  response_templates = {
    "application/json" = ""
  }
}
