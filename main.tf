resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = var.host_domain
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.private_ip]
}

resource "aws_key_pair" "this" {
  key_name   = "${var.environment}-gitlab"
  public_key = base64decode(aws_ssm_parameter.public_key.value)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "public_key" {
  name  = "${var.environment}-gitlab-public-ssh-key"
  type  = "SecureString"
  value = base64encode(tls_private_key.this.public_key_openssh)
}

resource "aws_ssm_parameter" "private_key" {
  name  = "${var.environment}-gitlab-private-ssh-key"
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
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules       = ["https-443-tcp", "ssh-tcp"]
  ingress_with_cidr_blocks = [ for block in var.ingress_cidr_blocks: 
    {
      from_port   = 2222
      to_port     = 2222
      protocol    = "tcp"
      description = "SSH port for Gitlab container port-forward"
      cidr_blocks = block
    }
  ]
  egress_rules        = ["all-all"]
}

resource "aws_backup_vault" "gitlab" {
  count = var.backups_enabled ? 1 : 0
  name  = "${var.environment}-gitlab"
}


resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-gitlab"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-gitlab"
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

resource "aws_iam_role_policy" "certbot_r53" {
  name   = "certbot-r53"
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

resource "aws_iam_role_policy" "gitlab_backup" {
  count   = var.backups_enabled ? 1 : 0
  name    = "backup"
  role    = aws_iam_role.this.id
  policy  = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "StartBackup",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "backup:StartBackupJob"
            ],
            "Resource": [
                "${aws_backup_vault.gitlab[0].arn}",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSBackupDefaultServiceRole"
            ]
        },
        {
            "Sid": "DescribeJob",
            "Effect": "Allow",
            "Action": "backup:DescribeBackupJob",
            "Resource": "*"
        }
    ]
  }
  EOF
}

resource "aws_launch_template" "gitlab" {
  name                                  = "${var.environment}-gitlab"
  image_id                              = data.aws_ami.ubuntu.id
  instance_type                         = var.instance_type

  key_name                              = aws_key_pair.this.key_name
  ebs_optimized                         = true

  user_data                             = base64encode(templatefile("${path.module}/resources/templates/user_data.tpl", 
    {
      docker_compose_yml  = base64encode(templatefile("${path.module}/resources/templates/docker-compose.yml.tpl", 
        {
          host_domain = var.host_domain
        })),
      install_script      = base64encode(templatefile("${path.module}/resources/scripts/install.sh",
        {
          certbot_email   = var.certbot_email
          host_domain     = var.host_domain
          make_fs         = var.gitlab_snapshot_id == null ? true : false
          backups_enabled = var.backups_enabled
        })),
      backup_script      = base64encode(templatefile("${path.module}/resources/scripts/backup.sh",
        {
          vol_arn         = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].arn : aws_ebs_volume.gitlab.arn
          backup_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSBackupDefaultServiceRole"
          vault_name      = aws_backup_vault.gitlab[0].id
          aws_region      = data.aws_region.current.name
          backups_enabled = var.backups_enabled
          retention_days  = var.retention_days
        })),
      renew_script      = base64encode(templatefile("${path.module}/resources/scripts/renew.sh",
        {
          certbot_email   = var.certbot_email
          host_domain     = var.host_domain
        }))
    }
  ))

  network_interfaces {
    subnet_id                   = var.subnet_id
    security_groups             = [module.security_group_gitlab.security_group_id]
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name             = "/dev/sda1"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags                        = {
      Name = "${var.environment}-gitlab"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ebs_volume.gitlab]
}

resource "aws_ebs_volume" "gitlab" {
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = var.gitlab_volume_size
  tags = {
    Name = "${var.environment}-gitlab"
  }
}


resource "aws_ebs_volume" "gitlab_snapshot" {
  count             = var.gitlab_snapshot_id != null ? 1 : 0
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = var.gitlab_volume_size
  snapshot_id       = var.gitlab_snapshot_id
  tags = {
    Name        = "${var.environment}-gitlab-snapshot"
    snapshot_id = var.gitlab_snapshot_id
  }
}

resource "aws_instance" "this" {
  iam_instance_profile = aws_iam_instance_profile.this.name
  launch_template {
    id      = aws_launch_template.gitlab.id
    version = "$Latest"
  }
  tags = {
    Name        = "${var.environment}-gitlab"
    snapshot_id = var.gitlab_snapshot_id
  }
}


resource "aws_volume_attachment" "gitlab" {
  device_name = "/dev/sdh"
  volume_id   = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].id : aws_ebs_volume.gitlab.id
  instance_id = aws_instance.this.id
}

resource "aws_volume_attachment" "swap" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.swap.id
  instance_id = aws_instance.this.id
}
