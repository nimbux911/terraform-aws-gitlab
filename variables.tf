variable "environment" {}
variable "domain" {}
variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "ingress_cidr_blocks" {
  default = []
}
variable "zone_id" {}
variable "email" {}
variable "swap_volume_size" {}
variable "subnet_id" {
    type = string
}
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

variable "gitlab_conf_smtp" {
  type = map
  default = {
    smtp_address = ""
    smtp_port = ""
  }
}

variable "backups_enabled" {
    type    = bool
    default = false
}

variable "retention_days" {
    type    = number
    default = null
}

variable "gitlab_snapshot_id" {
    type    = string
    default = null
}

variable "gitlab_volume_size" {
    type    = number
    default = 20
}