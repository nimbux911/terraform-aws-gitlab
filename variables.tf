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

variable "json_max_file" {
  default = ""
}

variable "gitlab_rb_extra_conf" {
  default = {}
}
variable "vault_name" {
    
}