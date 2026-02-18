# Enable Amazon Inspector for ECR scanning
resource "aws_inspector2_enabler" "inspector" {
  count          = var.enable_security_scanning ? 1 : 0
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_securityhub_account" "securityhub" {
  count = var.enable_security_scanning ? 1 : 0
}

# Enable AWS Inspector integration in Security Hub
resource "aws_securityhub_product_subscription" "inspector" {
  count       = var.enable_security_scanning ? 1 : 0
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
}

# Configure ECR enhanced scanning rules
resource "aws_ecr_registry_scanning_configuration" "enhanced" {
  count     = var.enable_security_scanning ? 1 : 0
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
  value       = try(aws_securityhub_account.securityhub[0].id, null)
}

output "inspector_enabled" {
  description = "Inspector enabled"
  value       = try(aws_inspector2_enabler.inspector[0].id, null)
}
