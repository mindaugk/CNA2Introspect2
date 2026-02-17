# ECR Repositories for MK Services
locals {
  ecr_repositories = {
    claimstatus = {
      name    = "claim-status-api"
      service = "ClaimStatusApi"
    }
  }
}

# ECR Repositories
resource "aws_ecr_repository" "mk_services" {
  for_each = local.ecr_repositories

  name                 = each.value.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = each.value.name
    Environment = "dev"
    ManagedBy   = "terraform"
    Service     = each.value.service
  }
}

# Lifecycle policies to keep only the last 10 images
resource "aws_ecr_lifecycle_policy" "mk_services_policy" {
  for_each = local.ecr_repositories

  repository = aws_ecr_repository.mk_services[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Outputs
output "ecr_repository_urls" {
  description = "Map of all ECR repository URLs"
  value = {
    for key, repo in aws_ecr_repository.mk_services :
    key => repo.repository_url
  }
}

output "ecr_registry_id" {
  description = "Registry ID (AWS Account ID)"
  value       = aws_ecr_repository.mk_services["claimstatus"].registry_id
}

output "ecr_claimstatus_repository_url" {
  description = "URL of the Claim Status API ECR repository"
  value       = aws_ecr_repository.mk_services["claimstatus"].repository_url
}
