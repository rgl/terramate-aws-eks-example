generate_hcl "_inputs.auto.tfvars" {
  content {
    project              = global.project
    environment          = global.environment
    region               = global.region
    stack                = terramate.stack.id
    repository_name_path = global.cluster_name
    images               = global.source_images
  }
}
