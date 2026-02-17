variable "claim_api_base_url" {
  description = "Base URL for the Kubernetes HTTP service (e.g., http://<nlb-dns>)"
  type        = string
}

resource "aws_apigatewayv2_api" "claim_status_http_api" {
  name          = "claim-status-http-api"
  protocol_type = "HTTP"

  tags = {
    Name        = "claim-status-http-api"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_apigatewayv2_integration" "claim_status_integration" {
  api_id                 = aws_apigatewayv2_api.claim_status_http_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  payload_format_version = "1.0"
  integration_uri        = "${var.claim_api_base_url}/{proxy}"
}

resource "aws_apigatewayv2_route" "claim_status_proxy" {
  api_id    = aws_apigatewayv2_api.claim_status_http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.claim_status_integration.id}"
}

resource "aws_apigatewayv2_stage" "claim_status_stage" {
  api_id      = aws_apigatewayv2_api.claim_status_http_api.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Name        = "claim-status-http-api-prod"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

output "claim_status_http_api_url" {
  description = "Base URL for the Claim Status HTTP API"
  value       = aws_apigatewayv2_stage.claim_status_stage.invoke_url
}
