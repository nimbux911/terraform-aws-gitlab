# Security group

locals {
  rules = [ { "port" = 443,  "protocol" = "tcp" },
            { "port" = 22,   "protocol" = "tcp" },
            { "port" = 1194, "protocol" = "udp" },
            { "port" = 2222, "protocol" = "tcp" } ]

  # Renders one rule for each item in local.rules associated to each element in var.source_security_group_id as source
  rules_source_sg = flatten([
    for source_sg in var.source_security_group_id : [
      for rule in local.rules : {
        source_sg     = source_sg
        port          = rule["port"]
        protocol      = rule["protocol"]
      } 
    ]
  ])

  # Renders one rule for every entry en local.rules associated to cidr list as source
  rules_source_cidr = flatten([
    for rule in local.rules : {
      source_cidr   = var.ingress_cidr_blocks
      port          = rule["port"]
      protocol      = rule["protocol"]
    }
  ])


}

resource "aws_security_group" "gitlab" {
  name        = "${var.environment}-gitlab"
  description = "Security group for the gitlab EC2"
  vpc_id      = var.vpc_id
  tags        = {
    Name = "${var.environment}-gitlab"
  }
}

resource "aws_security_group_rule" "ingress_from_sg" {
  for_each                 = {
    for rule in local.rules_source_sg: "${rule.source_sg}_${rule.port}_${rule.protocol}" => rule
  }

  security_group_id        = aws_security_group.gitlab.id
  type                     = "ingress"
  description              = "Ingress Rule"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.source_sg
}

resource "aws_security_group_rule" "ingress_from_cidr" {
  for_each                 = {
    for rule in local.rules_source_cidr: "${rule.port}_${rule.protocol}" => rule
  }

  security_group_id        = aws_security_group.gitlab.id
  type                     = "ingress"
  description              = "Ingress Rule"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.source_cidr
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.gitlab.id
  type              = "egress"
  description       = "Outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
