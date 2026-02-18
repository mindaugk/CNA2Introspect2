resource "kubernetes_deployment_v1" "claim_status_api" {
  metadata {
    name      = "claim-status-api"
    namespace = "default"
    labels = {
      app = "claim-status-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "claim-status-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "claim-status-api"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.claim_status_api.metadata[0].name
        container {
          name  = "claim-status-api"
          image = "public.ecr.aws/docker/library/nginx:latest"

          port {
            container_port = 8080
          }

          env {
            name  = "AWS_REGION"
            value = "us-east-1"
          }

          env {
            name  = "CLAIMS_TABLE"
            value = "claims"
          }

          env {
            name  = "NOTES_BUCKET"
            value = aws_s3_bucket.claim_notes.bucket
          }

          env {
            name  = "NOTES_KEY_TEMPLATE"
            value = "claims/%s/note-01.txt"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account_v1" "claim_status_api" {
  metadata {
    name      = "claim-status-api"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.claim_status_api_irsa.arn
    }
    labels = {
      app = "claim-status-api"
    }
  }
}

resource "aws_iam_role" "claim_status_api_irsa" {
  name = "claim-status-api-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:default:claim-status-api"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "claim_status_api_irsa" {
  role = aws_iam_role.claim_status_api_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.claims.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.claim_notes.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}
