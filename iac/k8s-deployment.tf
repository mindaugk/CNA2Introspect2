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
            value = "claim-notes"
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
