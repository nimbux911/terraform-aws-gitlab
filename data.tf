data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_ssm_parameter" "key_pair" {
  count = var.gitlab_key_pair == {} ? 0 : 1

  name = var.gitlab_key_pair.ssm_private_key_name
  with_decryption = true
}
