data "aws_iam_policy_document" "gitlab_backup_replication" {
  count = var.backup_replication_enabled ? 1 : 0

  statement {
    sid = "ListRecoveryPoints"

    actions = [
      "backup:ListRecoveryPointsByBackupVault",
    ]

    resources = [aws_backup_vault.gitlab[0].arn]
  }

  statement {
    sid = "InspectSnapshots"

    actions = [
      "ec2:DescribeSnapshots",
      "ec2:DescribeSnapshotAttribute",
    ]

    resources = ["*"]
  }

  statement {
    sid = "ShareSnapshots"

    actions = [
      "ec2:ModifySnapshotAttribute",
    ]

    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot/*"]
  }

  statement {
    sid = "AssumeDestinationRole"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [var.backup_replication_destination_role_arn]
  }
}

resource "aws_iam_role_policy" "gitlab_backup_replication" {
  count = var.backup_replication_enabled ? 1 : 0

  name   = "backup-replication"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.gitlab_backup_replication[0].json
}
