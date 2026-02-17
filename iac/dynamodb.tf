# DynamoDB table for claim status
resource "aws_dynamodb_table" "claims" {
  name         = "claims"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "claims"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

locals {
  claims_seed_items = jsondecode(file("${path.module}/../mocks/claims.json"))
}

resource "aws_dynamodb_table_item" "claims_seed" {
  for_each   = { for item in local.claims_seed_items : item.id => item }
  table_name = aws_dynamodb_table.claims.name
  hash_key   = "id"

  item = jsonencode({
    id           = { S = each.value.id }
    status       = { S = each.value.status }
    policyId     = { S = each.value.policyId }
    claimantName = { S = each.value.claimantName }
    adjusterId   = { S = each.value.adjusterId }
    amount       = { N = tostring(each.value.amount) }
    updatedAt    = { S = each.value.updatedAt }
  })
}

output "claims_table_name" {
  description = "DynamoDB table name for claims"
  value       = aws_dynamodb_table.claims.name
}

output "claims_table_arn" {
  description = "DynamoDB table ARN for claims"
  value       = aws_dynamodb_table.claims.arn
}
