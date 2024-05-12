stack {
  name        = "eks-workloads"
  description = "eks-workloads"
  id          = "03b490d2-21d2-4bff-bbea-77ee2f74de35"
  after       = ["../ecr", "../eks-adot-collector", "../eks-trust-manager"]
}
