terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "cna-lab-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.mk_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.mk_cluster.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.mk_cluster.name,
      "--profile",
      "cna-lab-1"
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.mk_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.mk_cluster.certificate_authority[0].data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.mk_cluster.name,
        "--profile",
        "cna-lab-1"
      ]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
