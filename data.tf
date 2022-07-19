data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

data "aws_acm_certificate" "this" {
  domain   = var.domain
  statuses = ["ISSUED"]
}
