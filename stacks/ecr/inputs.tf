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

variable "stack" {
  type = string
}

# get the available locations with: aws ec2 describe-regions | jq -r '.Regions[].RegionName' | sort
variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "repository_name_path" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+(/[a-z][a-z0-9-]+)+$", var.repository_name_path))
    error_message = "Invalid repository_name_path."
  }
}

variable "images" {
  type = map(object({
    name = string
    tag  = string
  }))
}
