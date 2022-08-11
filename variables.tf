variable "environment" {}
variable "domain" {}
variable "private_subnet_ids" {}
variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "ingress_cidr_blocks" {
  default = []
}
variable "zone_id" {}
variable "email" {}
variable "swap_volume_size" {}
variable "gitlab_version" {
  default = "latest"
}
variable "source_security_group_id" {
  default = ""
}
