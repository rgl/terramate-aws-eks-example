// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = "1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.41.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Stack       = var.stack
    }
  }
}
