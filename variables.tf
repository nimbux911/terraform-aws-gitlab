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

variable "volume_size" {
  type    = string
  default = null
}
variable "gitlab_version" {
  default = "latest"
}
variable "source_security_group_id" {
  default = []
}
variable "gitlab_key_pair" {
  default = {}
}
variable "external_db" {
  type = map
  default = {
    db_host = ""
    db_password = ""
  }
}
