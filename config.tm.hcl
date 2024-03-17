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
      tag = "0.0.6"
    }
    kubernetes-hello = {
      # see https://hub.docker.com/repository/docker/ruilopes/kubernetes-hello
      # see https://github.com/rgl/kubernetes-hello
      name = "docker.io/ruilopes/kubernetes-hello"
      # renovate: datasource=docker depName=ruilopes/kubernetes-hello
      tag = "v0.0.0.202403171105-test"
    }
  }
}

# see https://github.com/hashicorp/terraform
globals "terraform" {
  # renovate: datasource=github-releases depName=hashicorp/terraform
  version = "1.7.5"
}

# see https://registry.terraform.io/providers/hashicorp/aws
# see https://github.com/hashicorp/terraform-provider-aws
globals "terraform" "providers" "aws" {
  # renovate: datasource=terraform-provider depName=hashicorp/aws
  version = "5.41.0"
}

# see https://registry.terraform.io/providers/hashicorp/cloudinit
# see https://github.com/hashicorp/terraform-provider-cloudinit
globals "terraform" "providers" "cloudinit" {
  # renovate: datasource=terraform-provider depName=hashicorp/cloudinit
  version = "2.3.3"
}

# see https://registry.terraform.io/providers/hashicorp/kubernetes
# see https://github.com/hashicorp/terraform-provider-kubernetes
globals "terraform" "providers" "kubernetes" {
  # renovate: datasource=terraform-provider depName=hashicorp/kubernetes
  version = "2.27.0"
}

# see https://registry.terraform.io/providers/hashicorp/helm
# see https://github.com/hashicorp/terraform-provider-helm
globals "terraform" "providers" "helm" {
  # renovate: datasource=terraform-provider depName=hashicorp/helm
  version = "2.12.1"
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
  version = "0.11.1"
}

# see https://registry.terraform.io/providers/hashicorp/tls
# see https://github.com/hashicorp/terraform-provider-tls
globals "terraform" "providers" "tls" {
  # renovate: datasource=terraform-provider depName=hashicorp/tls
  version = "4.0.5"
}
