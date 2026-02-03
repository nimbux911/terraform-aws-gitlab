## [1.1.1] - 2026-02-03

- Fix backup script race condition when stopping GitLab containers.
- Ensure GitLab services are fully stopped before docker-compose down.
- Add logging to backup execution for easier troubleshooting.

## [1.1.0] - 2026-01-22

- Allow configuring s3 storage for artifacts.

## [1.0.2] - 2022-10-31

- Fix renewal certificate logic.

## [1.0.1] - 2022-12-30

- Swap volume to EC2 instance.

## [1.0.0] - 2022-10-07

- Self-hosted Gitlab Docker running on a EC2 instance.
- Automated backups and restore.
