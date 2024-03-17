variable "stack" {
  type = string
}

# get the available locations with: aws ec2 describe-regions | jq -r '.Regions[].RegionName' | sort
variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "aws-eks-example"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.project))
    error_message = "Invalid project."
  }
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Invalid environment."
  }
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.cluster_name))
    error_message = "Invalid cluster name."
  }
}

variable "ingress_domain" {
  type        = string
  description = "The DNS domain name used to fully qualify the ingress objects domain"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+(\\.[a-z][a-z0-9-]+)+$", var.ingress_domain))
    error_message = "Invalid ingress domain."
  }
}

variable "source_images" {
  type = map(object({
    name = string
    tag  = string
  }))
}
