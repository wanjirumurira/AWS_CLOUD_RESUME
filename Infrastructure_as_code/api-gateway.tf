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

# resource "aws_api_gateway_method" "proxy_root" {
#    rest_api_id   = aws_api_gateway_rest_api.visitor_apigw.id
#    resource_id   = aws_api_gateway_rest_api.visitor_apigw.root_resource_id
#    http_method   = "GET"
#    authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_root" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
#   resource_id = aws_api_gateway_method.proxy_root.resource_id
#   http_method = aws_api_gateway_method.proxy_root.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"  # With AWS_PROXY, it causes API gateway to call into the API of another AWS service
#   uri                     = aws_lambda_function.visitor_function.invoke_arn
  
# }

# OPTIONS method response.
resource "aws_api_gateway_method_response" "options" {
  depends_on = [ aws_api_gateway_method.visitor_method ]
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_method.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}


resource "aws_api_gateway_integration_response" "cors" {
  depends_on = [aws_api_gateway_integration.lambda, aws_api_gateway_method_response.options]
  rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_method.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'", # replace with hostname of frontend (CloudFront)
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST'" # remove or add HTTP methods as needed
  }
}

resource "aws_api_gateway_deployment" "visitor_deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda,
   ]
   rest_api_id = aws_api_gateway_rest_api.visitor_apigw.id
   stage_name  = "test"
}
