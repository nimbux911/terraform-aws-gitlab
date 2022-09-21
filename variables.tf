variable "environment" {}
variable "private_subnet_ids" {}
variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "ingress_cidr_blocks" {}
variable "zone_id" {}
variable "email" {}
variable "swap_volume_size" {}
variable "dns" {}
variable "backup_retention_days" {
    type = number
}

variable "backup_schedule_frequency" {
    type = string
  
}

variable "backup_plan_name" {
    type = string
}

variable "backup_plan_rule_name" {
    type = string
}

variable "backup_plan_resources_selection_name" {
    type = string
}

variable "backup_plan_role_name" {
    type = string
}

variable "backup_plan_selection_key" {
    type = string
}

variable "backup_plan_selection_value" {
    type = string
}

variable "configure_backups" {
    type = bool
    default = false
}

variable "managed_policy_arns" {
    type = list(string)
    default = []
}

variable "create_swap" {
    type = bool
    default = false
}