generate_hcl "_providers.tf" {
  content {
    terraform {
      required_version = global.terraform.version
      required_providers {
        # see https://registry.terraform.io/providers/hashicorp/aws
        # see https://github.com/hashicorp/terraform-provider-aws
        aws = {
          source  = "hashicorp/aws"
          version = global.terraform.providers.aws.version
        }
        # see https://registry.terraform.io/providers/hashicorp/cloudinit
        # see https://github.com/hashicorp/terraform-provider-cloudinit
        cloudinit = {
          source  = "hashicorp/cloudinit"
          version = global.terraform.providers.cloudinit.version
        }
        # see https://registry.terraform.io/providers/hashicorp/kubernetes
        # see https://github.com/hashicorp/terraform-provider-kubernetes
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = global.terraform.providers.kubernetes.version
        }
        # see https://registry.terraform.io/providers/hashicorp/helm
        # see https://github.com/hashicorp/terraform-provider-helm
        helm = {
          source  = "hashicorp/helm"
          version = global.terraform.providers.helm.version
        }
        # see https://registry.terraform.io/providers/hashicorp/local
        # see https://github.com/hashicorp/terraform-provider-local
        local = {
          source  = "hashicorp/local"
          version = global.terraform.providers.local.version
        }
        # see https://registry.terraform.io/providers/hashicorp/time
        # see https://github.com/hashicorp/terraform-provider-time
        time = {
          source  = "hashicorp/time"
          version = global.terraform.providers.time.version
        }
        # see https://registry.terraform.io/providers/hashicorp/tls
        # see https://github.com/hashicorp/terraform-provider-tls
        tls = {
          source  = "hashicorp/tls"
          version = global.terraform.providers.tls.version
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
  }
}
