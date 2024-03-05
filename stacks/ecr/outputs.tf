output "registry_region" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-eks-example/otel-example
  #                     ^^^^^^^^^
  #                     region
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr_repository["otel-example"].repository_url)["region"]
}

output "registry_domain" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-eks-example/otel-example
  #      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #      domain
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr_repository["otel-example"].repository_url)["domain"]
}

output "images" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-eks-example/otel-example:1.2.3
  value = {
    for key, value in var.images : key => "${module.ecr_repository[key].repository_url}:${value.tag}"
  }
}
