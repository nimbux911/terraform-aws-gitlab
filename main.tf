resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = "${var.dns}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.private_ip]
}

resource "aws_key_pair" "this" {
  key_name   = "${var.environment}-2-gitlab"
  public_key = base64decode(aws_ssm_parameter.public_key.value)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "public_key" {
  name  = "${var.environment}-2-gitlab-public-ssh-key"
  type  = "SecureString"
  value = base64encode(tls_private_key.this.public_key_openssh)
}

resource "aws_ssm_parameter" "private_key" {
  name  = "${var.environment}-2-gitlab-private-ssh-key"
  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(tls_private_key.this.private_key_pem)
}


module "security_group_gitlab" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  
  description         = "Security group for the gitlab EC2"
  name                = "${var.environment}-gitlab"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = [var.ingress_cidr_blocks]
  ingress_rules       = ["https-443-tcp", "ssh-tcp", "openvpn-udp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 2222
      to_port     = 2222
      protocol    = "tcp"
      description = "SSH port override for host OS"
      cidr_blocks = var.ingress_cidr_blocks
    }]
  egress_rules        = ["all-all"]
}

output "security_group_id" {
  value       = module.security_group_gitlab.security_group_id
}

resource "aws_instance" "this" {
  iam_instance_profile        = aws_iam_instance_profile.this.name
  ami                         = var.ami_id
  instance_type               = var.instance_type
  tags                        = {
    name = "${var.environment}-2-gitlab"
    Backup = "true"
  }
  subnet_id                   = var.private_subnet_ids[0]
  security_groups             = [module.security_group_gitlab.security_group_id]
  key_name                    = "${var.environment}-2-gitlab"
  associate_public_ip_address = false
  user_data                   = templatefile("${path.module}/resources/templates/user_data.tpl", 
    {
      docker_compose_yml = base64encode(templatefile("${path.module}/resources/templates/docker-compose.yml.tpl", 
        {
          hostname = "${var.dns}"
        })),
      install_script = base64encode(templatefile("${path.module}/resources/scripts/install.sh",
        {
          email = var.email
          dns = var.dns
        }))
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "swap" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.swap_volume_size
}

resource "aws_volume_attachment" "swap" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.swap.id
  instance_id = aws_instance.this.id
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-2-gitlab"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-2-gitlab"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-2-gitlab"
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:GetChange"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect" : "Allow",
            "Action" : [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource" : [
                "arn:aws:route53:::hostedzone/${var.zone_id}"
            ]
        }
    ]
}
  EOF
}

locals {
  backups = {
    schedule  = var.backup_schedule_frequency
    retention = var.backup_retetion_days
  }
}

resource "aws_backup_plan" "example-backup-plan" {
  count             = var.configure_backups ? 1 : 0
  name = var.backup_plan_name

  rule {
    rule_name         = var.backup_plan_rule_name
    target_vault_name = "Default"
    schedule          = local.backups.schedule
    start_window      = 60
    completion_window = 300

    lifecycle {
      delete_after = local.backups.retention
    }
  }
}

resource "aws_backup_selection" "example-server-backup-selection" {
  count             = var.configure_backups ? 1 : 0
  iam_role_arn      = aws_iam_role.example-aws-backup-service-role[0].arn
  name              = var.backup_plan_resources_selection_name
  plan_id           = aws_backup_plan.example-backup-plan[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_plan_selection_key
    value = var.backup_plan_selection_value
  }
}


## IAM permissions

resource "aws_iam_role" "example-aws-backup-service-role" {
  count             = var.configure_backups ? 1 : 0
  name = var.backup_plan_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "backup.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "example-backup-service-aws-backup-role-policy" {
  count             = var.configure_backups ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.example-aws-backup-service-role[0].name
}

resource "aws_iam_role_policy_attachment" "example-restore-service-aws-backup-role-policy" {
  count             = var.configure_backups ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.example-aws-backup-service-role[0].name
}