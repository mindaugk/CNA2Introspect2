# StorageClass for EKS Auto Mode with correct provisioner
resource "kubernetes_storage_class_v1" "gp3_auto_mode" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.eks.amazonaws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  # Required for EKS Auto Mode
  allowed_topologies {
    match_label_expressions {
      key    = "eks.amazonaws.com/compute-type"
      values = ["auto"]
    }
  }

  depends_on = [
    aws_eks_cluster.mk_cluster
  ]
}
