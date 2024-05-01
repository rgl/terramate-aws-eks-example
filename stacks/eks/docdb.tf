locals {
  example_docdb_port = 27017
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster
resource "aws_docdb_cluster" "example" {
  cluster_identifier           = var.cluster_name
  availability_zones           = module.vpc.azs
  db_subnet_group_name         = module.vpc.database_subnet_group_name
  vpc_security_group_ids       = [aws_security_group.example_docdb.id]
  port                         = local.example_docdb_port
  engine                       = "docdb"
  engine_version               = "5.0.0"
  master_username              = "master"
  master_password              = "Ex0mple!" # TODO move to a secret.
  preferred_maintenance_window = "mon:00:00-mon:03:00"
  preferred_backup_window      = "04:00-06:00"
  backup_retention_period      = 1 # [days]. min 1.
  skip_final_snapshot          = true
  apply_immediately            = true
  lifecycle {
    ignore_changes = [
      # TODO why is this changing from 2 to 3 azs after initial creation?
      #      see https://github.com/hashicorp/terraform-provider-aws/issues/37210
      availability_zones,
    ]
  }
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_instance
resource "aws_docdb_cluster_instance" "example" {
  count                        = 1
  identifier                   = "example${count.index}"
  cluster_identifier           = aws_docdb_cluster.example.id
  instance_class               = "db.t3.medium"
  preferred_maintenance_window = "tue:00:00-tue:03:00"
  apply_immediately            = true
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "example_docdb" {
  vpc_id      = module.vpc.vpc_id
  name        = "example-docdb"
  description = "Example DocumentDB Database"
  tags = {
    Name = "${var.cluster_name}-docdb"
  }
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
resource "aws_vpc_security_group_ingress_rule" "example_docdb_mongo" {
  for_each = { for i, cidr_block in module.vpc.private_subnets_cidr_blocks : module.vpc.azs[i] => cidr_block }

  security_group_id = aws_security_group.example_docdb.id
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  from_port         = local.example_docdb_port
  to_port           = local.example_docdb_port
  tags = {
    Name = "${var.cluster_name}-private-${each.key}-docdb-mongo"
  }
}
