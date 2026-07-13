## [1.6.0] - 2026-07-13
- Add `backup_cron_expression` variable to configure the instance cron schedule for GitLab backups.

## [1.5.0] - 2026-07-13

- Add configurable SMTP settings for GitLab email delivery.
- Add Bitbucket OmniAuth sign-in support.
- Add optional Bitbucket Cloud import source support.

## [1.4.0] - 2026-06-24

- Add configurable Docker bridge and address pool CIDRs to avoid conflicts with routed VPC networks.

## [1.3.0] - 2026-06-19
- Add `custom_ingress_rules` variable to allow configuring custom inbound CIDR rules.

## [1.2.0] - 2026-06-09

- Add Cloudflare support.
- Mount GitLab EBS volume by stable volume ID.
- Add configurable stack name for GitLab resources.
- Add configurable public and private SSH key SSM parameter names.
- Modify install and backup scripts to work with Ubuntu 26.04 LTS.

## [1.1.1] - 2026-02-03

- Fix backup script race condition when stopping GitLab containers.
- Ensure GitLab services are fully stopped before docker-compose down.
- Add logging to backup execution for easier troubleshooting.
- Add ignore changes for launch_template and user_data.

## [1.1.0] - 2026-01-22

- Allow configuring s3 storage for artifacts.

## [1.0.2] - 2022-10-31

- Fix renewal certificate logic.

## [1.0.1] - 2022-12-30

- Swap volume to EC2 instance.

## [1.0.0] - 2022-10-07

- Self-hosted Gitlab Docker running on a EC2 instance.
- Automated backups and restore.
