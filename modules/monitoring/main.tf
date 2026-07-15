resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = var.role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "custom_metrics" {
  name = "gitlab-custom-metrics"
  role = var.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cloudwatch:PutMetricData"
      Resource = "*"
      Condition = {
        StringEquals = {
          "cloudwatch:namespace" = var.metrics_namespace
        }
      }
    }]
  })
}

resource "aws_ssm_document" "this" {
  name            = "${var.role_name}-monitoring"
  document_type   = "Command"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "2.2"
    description   = "Configure CloudWatch monitoring for GitLab"
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "configureGitLabMonitoring"
      inputs = {
        runCommand = [<<-SHELL
          install -d -m 0755 /usr/local/lib/gitlab-monitoring

          printf '%s' '${base64encode(templatefile("${path.module}/resources/scripts/configure-monitoring.sh.tftpl", {
          region      = var.region
          environment = var.environment
          }))}' | base64 --decode > /usr/local/lib/gitlab-monitoring/configure-monitoring

          printf '%s' '${base64encode(templatefile("${path.module}/resources/scripts/gitlab-healthcheck-metric.sh.tftpl", {
          metrics_namespace = var.metrics_namespace
          region            = var.region
          environment       = var.environment
          healthcheck_url   = var.healthcheck_url
          }))}' | base64 --decode > /usr/local/bin/gitlab-healthcheck-metric

          printf '%s' '${base64encode(templatefile("${path.module}/resources/scripts/gitlab-cert-expiry-metric.sh.tftpl", {
          metrics_namespace = var.metrics_namespace
          region            = var.region
          environment       = var.environment
          cert_host         = var.cert_host
          cert_port         = var.cert_port
    }))}' | base64 --decode > /usr/local/bin/gitlab-cert-expiry-metric

          chmod 0755 /usr/local/lib/gitlab-monitoring/configure-monitoring /usr/local/bin/gitlab-healthcheck-metric /usr/local/bin/gitlab-cert-expiry-metric
          /usr/local/lib/gitlab-monitoring/configure-monitoring

          printf '%s\n' \
            '* * * * * root /usr/local/bin/gitlab-healthcheck-metric >/var/log/gitlab-healthcheck-metric.log 2>&1' \
            '17 */12 * * * root /usr/local/bin/gitlab-cert-expiry-metric >/var/log/gitlab-cert-expiry-metric.log 2>&1' \
            > /etc/cron.d/gitlab-cloudwatch-monitoring
SHELL
    ]
  }
}]
})
}

resource "aws_ssm_association" "this" {
  name = aws_ssm_document.this.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }

  max_concurrency = "1"
  max_errors      = "0"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy.custom_metrics,
  ]
}
