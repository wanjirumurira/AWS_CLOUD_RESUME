resource "aws_api_gateway_rest_api" "visitor_apigw" {
    name = "visitor_api"
    description = "Visitor API Gateway"
    endpoint_configuration {
      types = ["REGIONAL"]
    } 
}

resource "aws_api_gateway_resource" "visitor_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  parent_id = aws_api_gateway_rest_api.visitor_apigw.root_resource_id
  path_part =  "visitor"
}

resource "aws_api_gateway_method" "visitor_method" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id = aws_api_gateway_method.visitor_method.resource_id
  http_method = aws_api_gateway_method.visitor_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.visitor_function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.visitor_apigw.id
   resource_id   = aws_api_gateway_rest_api.visitor_apigw.root_resource_id
   http_method   = "GET"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # With AWS_PROXY, it causes API gateway to call into the API of another AWS service
  uri                     = aws_lambda_function.visitor_function.invoke_arn
  
}

resource "aws_api_gateway_deployment" "visitor_deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]
   rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
   stage_name  = "test"
}