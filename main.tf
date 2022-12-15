resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.private_ip]
}

output "security_group_id" {
  value       = aws_security_group.gitlab.id
}

output "priv_key" {
  value  = local_file.get_priv_key.content
}

resource "aws_instance" "this" {
  iam_instance_profile        = aws_iam_instance_profile.this.name
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [ aws_security_group.gitlab.id ]
  key_name                    = var.gitlab_key_pair == {} ? "${var.environment}-gitlab" : var.gitlab_key_pair.key_pair_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.volume_size == null ? null : var.volume_size
  }

  # user_data                   = file("${path.module}/resources/scripts/install.sh")
  user_data                             = base64encode(templatefile("${path.module}/resources/templates/user_data.tpl",
    {
      install_script    = file("${path.module}/resources/scripts/install.sh"),
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
          certbot_email   = var.email
          host_domain     = var.domain
        }))
    }))

  lifecycle {
    create_before_destroy = true
  }

  tags                        = {
    Name = "${var.environment}-gitlab"
    snapshot_id = var.gitlab_snapshot_id
  }

  depends_on = [aws_ebs_volume.gitlab]

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

resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-gitlab"
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
        }key_pair_name
    ]
  }
  EOF
}

# Backup 

resource "aws_backup_vault" "gitlab" {
  count = var.backups_enabled ? 1 : 0
  name  = "${var.environment}-gitlab"
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

resource "aws_volume_attachment" "gitlab" {
  device_name = "/dev/sdj"
  volume_id   = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].id : aws_ebs_volume.gitlab.id
  instance_id = aws_instance.this.id
}