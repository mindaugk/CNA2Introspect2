# EKS Cluster in Auto Mode
resource "aws_eks_cluster" "mk_cluster" {
  name     = "mk-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"  # Adjust to your desired Kubernetes version

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1a.id,
      aws_subnet.private_subnet_1b.id,
      aws_subnet.private_subnet_1c.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                   = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.eks_node_role.arn
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
    aws_iam_role_policy_attachment.eks_networking_policy,
    aws_iam_role_policy_attachment.eks_compute_policy,
    aws_iam_role_policy_attachment.eks_block_storage_policy,
    aws_iam_role_policy_attachment.eks_load_balancing_policy
  ]

  tags = {
    Name        = "mk-cluster"
    Environment = "dev"
    ManagedBy   = "terraform"
    Mode        = "Auto"
  }
}

# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.mk_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.37.0-eksbuild.1"  # Use latest compatible version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_cluster.mk_cluster,
    aws_iam_role_policy_attachment.eks_block_storage_policy
  ]

  tags = {
    Name        = "ebs-csi-driver"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Note: IAM user access is automatically granted via bootstrap_cluster_creator_admin_permissions = true

# EKS Access Entry for Federated User
resource "aws_eks_access_entry" "federated_user" {
  cluster_name  = aws_eks_cluster.mk_cluster.name
  principal_arn = "arn:aws:sts::872823407497:federated-user/c04-vlabuser176@stackroute.in"
  type          = "STANDARD"

  tags = {
    Name        = "federated-user-access"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Associate Admin Policy to Federated User
resource "aws_eks_access_policy_association" "federated_user_policy" {
  cluster_name  = aws_eks_cluster.mk_cluster.name
  principal_arn = "arn:aws:sts::872823407497:federated-user/c04-vlabuser176@stackroute.in"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.federated_user]
}

# Outputs
output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.mk_cluster.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = aws_eks_cluster.mk_cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data for the cluster"
  value       = aws_eks_cluster.mk_cluster.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.mk_cluster.name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.mk_cluster.arn
}
