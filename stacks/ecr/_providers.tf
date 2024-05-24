// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = "1.8.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.1"
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
