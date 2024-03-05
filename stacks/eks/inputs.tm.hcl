generate_hcl "_inputs.auto.tfvars" {
  content {
    stack        = terramate.stack.id
    region       = global.region
    project      = global.project
    environment  = global.environment
    cluster_name = global.cluster_name
  }
}

generate_hcl "_inputs_cloud_watch.auto.tfvars" {
  condition = terramate.stack.name == "eks"
  content {
    cluster_cloudwatch_log_group_retention_in_days = global.cluster_cloudwatch_log_group_retention_in_days
  }
}
