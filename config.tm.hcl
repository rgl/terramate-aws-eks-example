globals {
  project     = "aws-eks-example"
  environment = "dev"

  cluster_name = "${global.project}-${global.environment}"

  cluster_version = "1.29"

  cluster_cloudwatch_log_group_retention_in_days = 90

  ingress_domain = "example.test"

  # get the available regions with:
  #   aws ec2 describe-regions | jq -r '.Regions[].RegionName' | sort
  region = "eu-west-1"

  # images to copy into the aws account ecr registry as:
  #   ${cluster_name}/${source_images.key}:${source_images.value.tag}
  source_images = {
    # see https://github.com/rgl/opentelemetry-dotnet-playground/pkgs/container/opentelemetry-dotnet-playground
    # see https://github.com/rgl/opentelemetry-dotnet-playground
    otel-example = {
      name = "ghcr.io/rgl/opentelemetry-dotnet-playground"
      # renovate: datasource=docker depName=rgl/opentelemetry-dotnet-playground registryUrl=https://ghcr.io
      tag = "0.0.7"
    }
    kubernetes-hello = {
      # see https://hub.docker.com/repository/docker/ruilopes/kubernetes-hello
      # see https://github.com/rgl/kubernetes-hello
      name = "docker.io/ruilopes/kubernetes-hello"
      # renovate: datasource=docker depName=ruilopes/kubernetes-hello
      tag = "v0.0.202406081214"
    }
    # see https://github.com/rgl/aws-docdb-example/pkgs/container/aws-docdb-example
    # see https://github.com/rgl/aws-docdb-example
    docdb-example = {
      name = "ghcr.io/rgl/aws-docdb-example"
      # renovate: datasource=docker depName=rgl/aws-docdb-example registryUrl=https://ghcr.io
      tag = "0.0.1"
    }
  }
}

# see https://github.com/hashicorp/terraform
globals "terraform" {
  # renovate: datasource=github-releases depName=hashicorp/terraform
  version = "1.8.5"
}

# see https://registry.terraform.io/providers/hashicorp/aws
# see https://github.com/hashicorp/terraform-provider-aws
globals "terraform" "providers" "aws" {
  # renovate: datasource=terraform-provider depName=hashicorp/aws
  version = "5.53.0"
}

# see https://registry.terraform.io/providers/hashicorp/cloudinit
# see https://github.com/hashicorp/terraform-provider-cloudinit
globals "terraform" "providers" "cloudinit" {
  # renovate: datasource=terraform-provider depName=hashicorp/cloudinit
  version = "2.3.4"
}

# see https://registry.terraform.io/providers/hashicorp/kubernetes
# see https://github.com/hashicorp/terraform-provider-kubernetes
globals "terraform" "providers" "kubernetes" {
  # renovate: datasource=terraform-provider depName=hashicorp/kubernetes
  version = "2.30.0"
}

# see https://registry.terraform.io/providers/hashicorp/helm
# see https://github.com/hashicorp/terraform-provider-helm
globals "terraform" "providers" "helm" {
  # renovate: datasource=terraform-provider depName=hashicorp/helm
  version = "2.13.2"
}

# see https://registry.terraform.io/providers/hashicorp/http
# see https://github.com/hashicorp/terraform-provider-http
globals "terraform" "providers" "http" {
  # renovate: datasource=terraform-provider depName=hashicorp/http
  version = "3.4.3"
}

# see https://registry.terraform.io/providers/hashicorp/local
# see https://github.com/hashicorp/terraform-provider-local
globals "terraform" "providers" "local" {
  # renovate: datasource=terraform-provider depName=hashicorp/local
  version = "2.5.1"
}

# see https://registry.terraform.io/providers/hashicorp/time
# see https://github.com/hashicorp/terraform-provider-time
globals "terraform" "providers" "time" {
  # renovate: datasource=terraform-provider depName=hashicorp/time
  version = "0.11.2"
}

# see https://registry.terraform.io/providers/hashicorp/tls
# see https://github.com/hashicorp/terraform-provider-tls
globals "terraform" "providers" "tls" {
  # renovate: datasource=terraform-provider depName=hashicorp/tls
  version = "4.0.5"
}

# see https://registry.terraform.io/providers/hashicorp/external
# see https://github.com/hashicorp/terraform-provider-external
globals "terraform" "providers" "external" {
  # renovate: datasource=terraform-provider depName=hashicorp/external
  version = "2.3.3"
}
