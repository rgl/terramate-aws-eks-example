// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = "1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.45.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
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
