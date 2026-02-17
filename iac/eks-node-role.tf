# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name                 = "eksNodeRole"
  description          = "EKS node role"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "eksNodeRole"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Attach AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# NOTE: Modification start for missing role corrections
#

# Attach AmazonEKSWorkerNodePolicy
resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach AmazonEKS_CNI_Policy
resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#
# NOTE: Modification end for missing role corrections

# Attach EBS CSI Driver Policy for volume provisioning
resource "aws_iam_role_policy_attachment" "eks_node_ebs_csi_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Outputs
output "eks_node_role_arn" {
  description = "ARN of the EKS node role"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_node_role_name" {
  description = "Name of the EKS node role"
  value       = aws_iam_role.eks_node_role.name
}
