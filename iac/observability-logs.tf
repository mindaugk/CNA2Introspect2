resource "aws_cloudwatch_log_group" "eks_container_logs" {
  name              = var.container_logs_group_name
  retention_in_days = 7

  tags = {
    Name        = "eks-container-logs"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

resource "aws_iam_role" "fluent_bit_irsa" {
  name = "eks-fluent-bit-irsa"

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
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:aws-for-fluent-bit"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "fluent_bit_policy" {
  role = aws_iam_role.fluent_bit_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_service_account_v1" "aws_for_fluent_bit" {
  metadata {
    name      = "aws-for-fluent-bit"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit_irsa.arn
    }
  }
}

resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  namespace  = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.31"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.aws_for_fluent_bit.metadata[0].name
  }

  set {
    name  = "cloudWatchLogs.enabled"
    value = "true"
  }

  set {
    name  = "cloudWatchLogs.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "cloudWatchLogs.logGroupName"
    value = aws_cloudwatch_log_group.eks_container_logs.name
  }

  set {
    name  = "cloudWatchLogs.logStreamPrefix"
    value = "claim-status"
  }
}
