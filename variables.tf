variable "environment" {
    default = "test"
}
variable "subnet_id" {
    type = string
}
variable "vpc_id" {
    type = string
}
variable "instance_type" {
    type    = string
    default = "t3.micro"
}
variable "ingress_cidr_blocks" {
    type = list(string)
}
variable "zone_id" {
    type = string
}
variable "certbot_email" {
    type = string
}
variable "test_gitlab_volume_size" {
    type    = number
    default = 20
}
variable "host_domain" {
    type = string
}
variable "backups_enabled" {
    type    = bool
    default = false
}
variable "retention_days" {
    type    = number
    default = null
}
variable "test_gitlab_snapshot_id" {
    type    = string
    default = null
}
variable "swap_volume_size" {}