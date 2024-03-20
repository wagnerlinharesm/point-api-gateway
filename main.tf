provider "aws" {
  region = var.region
}

# -- ------------------------------------------------------
# -- gateway
# -- ------------------------------------------------------

data "aws_lambda_function" "point_lambda_authorizer" {
  function_name = "point_lambda_authorizer"
}

resource "aws_api_gateway_rest_api" "point_api_gateway" {
  name = "point_api_gateway"
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "validator"
  rest_api_id                 = aws_api_gateway_rest_api.point_api_gateway.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.point_api_gateway.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = ["arn:aws:cognito-idp:us-east-2:644237782704:userpool/us-east-2_3HJlRalTj"]
}

resource "aws_api_gateway_deployment" "point-api-gateway-deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.report_generate_integration
    ]
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "point_lambda_authorizer_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.point_lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.point_api_gateway.execution_arn}/*"
}

# -- ------------------------------------------------------
# -- route auth
# -- ------------------------------------------------------

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.point_api_gateway.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_method" {
  rest_api_id   = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id             = aws_api_gateway_resource.auth_resource.id
  http_method             = aws_api_gateway_method.auth_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:644237782704:function:point_lambda_authorizer/invocations"
}

# -- ------------------------------------------------------
# -- report route
# -- ------------------------------------------------------

data "aws_sqs_queue" "point_report_sqs_queue" {
  name = var.point_report_sqs_queue_name
}

resource "aws_iam_role" "report_generate_integration_iam_role" {
  name               = "report_generate_integration_iam_role"
  assume_role_policy = file("iam/policy/assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "point_report_sqs_iam_role_policy_attachment" {
  role       = aws_iam_role.report_generate_integration_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_api_gateway_resource" "report_resource" {
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.point_api_gateway.root_resource_id
  path_part   = "report"
}

resource "aws_api_gateway_resource" "report_generate_resource" {
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  parent_id   = aws_api_gateway_resource.report_resource.id
  path_part   = "generate"
}

resource "aws_api_gateway_method" "report_generate_post_method" {
  rest_api_id           = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id           = aws_api_gateway_resource.report_generate_resource.id
  http_method           = "POST"
  authorization         = "COGNITO_USER_POOLS"
  authorizer_id         = aws_api_gateway_authorizer.cognito_authorizer.id

  request_models        = {
    "application/json" = "Empty"
  }

  request_validator_id  = aws_api_gateway_request_validator.validator.id
}

resource "aws_api_gateway_method_response" "report_generate_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id = aws_api_gateway_resource.report_generate_resource.id
  http_method = aws_api_gateway_method.report_generate_post_method.http_method
  status_code = "201"
}

resource "aws_api_gateway_integration" "report_generate_integration" {
  rest_api_id               = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id               = aws_api_gateway_resource.report_generate_resource.id
  http_method               = aws_api_gateway_method.report_generate_post_method.http_method

  type                      = "AWS"
  integration_http_method   = "POST"
  passthrough_behavior      = "NEVER"

  credentials               = aws_iam_role.report_generate_integration_iam_role.arn
  uri                       = "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_sqs_queue.point_report_sqs_queue.name}"

  request_templates = {
    "application/json" = <<EOF
    {
      "Authorization": "$util.escapeJavaScript($input.params().header.get('Authorization'))",
    }
    EOF
  }

}

resource "aws_api_gateway_integration_response" "report_generate_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.point_api_gateway.id
  resource_id = aws_api_gateway_resource.report_generate_resource.id
  http_method = aws_api_gateway_method.report_generate_post_method.http_method
  status_code = aws_api_gateway_method_response.report_generate_post_method_response.status_code

  depends_on = [
    aws_api_gateway_integration.report_generate_integration
  ]
}