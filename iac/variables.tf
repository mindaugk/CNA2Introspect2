variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "mk-cluster"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "k8s_deployment_name" {
  description = "Kubernetes deployment name"
  type        = string
  default     = "claim-status-api"
}

variable "k8s_container_name" {
  description = "Kubernetes container name"
  type        = string
  default     = "claim-status-api"
}

variable "enable_security_scanning" {
  description = "Enable Inspector, Security Hub integration, and ECR enhanced scanning"
  type        = bool
  default     = false
}

variable "container_logs_group_name" {
  description = "CloudWatch Logs group for EKS container logs"
  type        = string
  default     = "/aws/eks/claim-status/container-logs"
}
