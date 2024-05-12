// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

cluster_name   = "aws-eks-example-dev"
environment    = "dev"
ingress_domain = "example.test"
project        = "aws-eks-example"
region         = "eu-west-1"
source_images = {
  docdb-example = {
    name = "ghcr.io/rgl/aws-docdb-example"
    tag  = "0.0.1"
  }
  kubernetes-hello = {
    name = "docker.io/ruilopes/kubernetes-hello"
    tag  = "v0.0.202405112126"
  }
  otel-example = {
    name = "ghcr.io/rgl/opentelemetry-dotnet-playground"
    tag  = "0.0.6"
  }
}
stack = "03b490d2-21d2-4bff-bbea-77ee2f74de35"
