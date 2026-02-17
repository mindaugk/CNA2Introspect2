# Wait for EKS cluster to be fully operational including webhooks
resource "null_resource" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.mk_cluster]
  
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${aws_eks_cluster.mk_cluster.name} --profile cna-lab-1 --region us-east-1"
  }
  
  provisioner "local-exec" {
    command     = "Start-Sleep -Seconds 120"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Kubernetes Service for Claim Status API
resource "kubernetes_service_v1" "claim_status_api" {
  metadata {
    name      = "claim-status-api"
    namespace = "default"
    
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"              = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"                  = "8080"
      "service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules" = "true"
      "service.beta.kubernetes.io/aws-load-balancer-subnets"                           = join(",", [
        aws_subnet.public_subnet_1a.id,
        aws_subnet.public_subnet_1b.id,
        aws_subnet.public_subnet_1c.id,
        aws_subnet.public_subnet_1d.id
      ])
    }
  }

  spec {
    selector = {
      app = "claim-status-api"
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  wait_for_load_balancer = true

  depends_on = [
    aws_eks_cluster.mk_cluster,
    null_resource.wait_for_cluster
  ]
}

# Output for Load Balancer Hostname
output "claim_status_api_loadbalancer_hostname" {
  description = "Hostname of the Claim Status API Load Balancer"
  value       = try(kubernetes_service_v1.claim_status_api.status[0].load_balancer[0].ingress[0].hostname, null)
}
