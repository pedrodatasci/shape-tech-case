resource "aws_redshiftserverless_namespace" "shape_ns" {
  namespace_name = "shape-namespace"
  db_name        = "shape_db"
}

resource "aws_redshiftserverless_workgroup" "shape_wg" {
  workgroup_name       = "shape-workgroup"
  namespace_name       = aws_redshiftserverless_namespace.shape_ns.namespace_name
  base_capacity        = 8
  publicly_accessible  = true
  enhanced_vpc_routing = false

  tags = {
    Name        = "shape-redshift-wg"
    Environment = "dev"
  }
}