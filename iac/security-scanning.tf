# Enable Amazon Inspector for ECR scanning
resource "aws_inspector2_enabler" "inspector" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_securityhub_account" "securityhub" {}

# Enable AWS Inspector integration in Security Hub
resource "aws_securityhub_product_subscription" "inspector" {
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
}

# Configure ECR enhanced scanning rules
resource "aws_ecr_registry_scanning_configuration" "enhanced" {
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

output "securityhub_enabled" {
  description = "Security Hub enabled"
  value       = aws_securityhub_account.securityhub.id
}

output "inspector_enabled" {
  description = "Inspector enabled"
  value       = aws_inspector2_enabler.inspector.id
}
