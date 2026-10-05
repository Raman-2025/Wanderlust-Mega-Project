terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0" # This forces Terraform to use the modern version
    }
  }
}

provider "aws" {
  # Configuration options
   region = "us-east-1"
}

# Tell Terraform to use the Helm provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.example.certificate_authority[0].data)
    
    # This uses your AWS credentials to log into the cluster
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.example.name]
      command     = "aws"
    }
  }
}