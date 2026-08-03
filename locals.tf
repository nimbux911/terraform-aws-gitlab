locals {
  gitlab_volume_id  = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].id : aws_ebs_volume.gitlab[0].id
  gitlab_volume_arn = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].arn : aws_ebs_volume.gitlab[0].arn
}
