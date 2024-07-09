// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = "1.9.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
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
