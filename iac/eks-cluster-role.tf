# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eksClusterRole"
  description        = "EKS control plane role"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "eksClusterRole"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Attach AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach AmazonEKSServicePolicy
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Attach AmazonEKSNetworkingPolicy
resource "aws_iam_role_policy_attachment" "eks_networking_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}

# Attach AmazonEKSComputePolicy
resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

# Attach AmazonEKSBlockStoragePolicy
resource "aws_iam_role_policy_attachment" "eks_block_storage_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

# Attach AmazonEKSLoadBalancingPolicy
resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

# Outputs
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster role"
  value       = aws_iam_role.eks_cluster_role.name
}
