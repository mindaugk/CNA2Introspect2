# S3 bucket for claim notes
resource "random_id" "notes_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "claim_notes" {
  bucket = "claim-notes-${random_id.notes_bucket_suffix.hex}"

  tags = {
    Name        = "claim-notes"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "claim_notes" {
  bucket = aws_s3_bucket.claim_notes.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "claim_notes" {
  bucket                  = aws_s3_bucket.claim_notes.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  notes_seed_items = jsondecode(file("${path.module}/../mocks/notes.json"))
}

resource "aws_s3_object" "claim_notes" {
  for_each = { for note in local.notes_seed_items : note.s3Key => note }

  bucket       = aws_s3_bucket.claim_notes.id
  key          = each.value.s3Key
  content      = jsonencode(each.value)
  content_type = "application/json"
}

output "claim_notes_bucket_name" {
  description = "S3 bucket name for claim notes"
  value       = aws_s3_bucket.claim_notes.bucket
}

output "claim_notes_bucket_arn" {
  description = "S3 bucket ARN for claim notes"
  value       = aws_s3_bucket.claim_notes.arn
}
