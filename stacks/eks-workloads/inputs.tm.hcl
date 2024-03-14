generate_hcl "_inputs.auto.tfvars" {
  content {
    stack          = terramate.stack.id
    region         = global.region
    project        = global.project
    environment    = global.environment
    cluster_name   = global.cluster_name
    ingress_domain = global.ingress_domain
    source_images  = global.source_images
  }
}
