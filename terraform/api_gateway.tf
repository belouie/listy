resource "aws_api_gateway_rest_api" "listy_api" {
  name = local.name
  tags = local.tags
}

resource "aws_api_gateway_gateway_response" "unauthorised" {
  rest_api_id   = aws_api_gateway_rest_api.listy_api.id
  status_code   = "401"
  response_type = "UNAUTHORIZED"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
  }
}

resource "aws_api_gateway_gateway_response" "forbidden" {
  rest_api_id   = aws_api_gateway_rest_api.listy_api.id
  status_code   = "403"
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
  }
}

resource "aws_api_gateway_gateway_response" "internal_server_error" {
  rest_api_id   = aws_api_gateway_rest_api.listy_api.id
  status_code   = "500"
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
  }
}

resource "aws_api_gateway_resource" "endpoint" {
  rest_api_id = aws_api_gateway_rest_api.listy_api.id
  parent_id   = aws_api_gateway_rest_api.listy_api.root_resource_id
  path_part   = "listy"
}

resource "aws_api_gateway_method" "endpoint" {
  rest_api_id   = aws_api_gateway_rest_api.listy_api.id
  resource_id   = aws_api_gateway_resource.endpoint.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "endpoint" {
  rest_api_id = aws_api_gateway_rest_api.listy_api.id
  resource_id = aws_api_gateway_resource.endpoint.id
  http_method = aws_api_gateway_method.endpoint.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "endpoint" {
  depends_on = [aws_api_gateway_method.endpoint, aws_api_gateway_method_response.endpoint]

  rest_api_id             = aws_api_gateway_rest_api.listy_api.id
  resource_id             = aws_api_gateway_method.endpoint.resource_id
  http_method             = aws_api_gateway_method.endpoint.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.listy_CRUD_function.invoke_arn
 }

resource "aws_api_gateway_integration_response" "endpoint" {
  depends_on = [aws_api_gateway_integration.endpoint]
  
  rest_api_id = aws_api_gateway_rest_api.listy_api.id
  resource_id = aws_api_gateway_resource.endpoint.id
  http_method = aws_api_gateway_method.endpoint.http_method
  status_code = aws_api_gateway_method_response.endpoint.status_code

  response_templates = {
    "application/json" = ""
  }
}

module "cors" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.listy_api.id
  api_resource_id = aws_api_gateway_resource.endpoint.id

  allow_headers = [
    "Authorization",
    "Content-Type",
    "X-Amz-Date",
    "X-Amz-Security-Token",
    "X-Api-Key",
    "X-Charge"
  ]
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [aws_api_gateway_integration_response.endpoint]

  rest_api_id = aws_api_gateway_rest_api.listy_api.id
  description = "Deployed endpoint at ${timestamp()}"
}

resource "aws_api_gateway_stage" "api" {
  stage_name    = local.environment
  rest_api_id   = aws_api_gateway_rest_api.listy_api.id
  deployment_id = aws_api_gateway_deployment.api.id

  tags = local.tags
}

resource "aws_lambda_permission" "api" {
  statement_id  = "${local.name}-AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = local.name
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.listy_api.id}/*/${aws_api_gateway_method.endpoint.http_method}${aws_api_gateway_resource.endpoint.path}"
}