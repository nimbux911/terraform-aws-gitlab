#!/bin/bash
export GITLAB_HOME=/home/ubuntu/gitlab
cd $GITLAB_HOME
docker exec gitlab gitlab-ctl stop
docker-compose down
vol_arn="${vol_arn}"
iam_role_arn="${backup_role_arn}"
vault_name="${vault_name}"
job_id=$(aws backup start-backup-job --lifecycle DeleteAfterDays=${retention_days} --backup-vault-name $vault_name --resource-arn $vol_arn --iam-role-arn $iam_role_arn --region ${aws_region} |jq -r '.BackupJobId')

job_status="RUNNING"
while [ "$job_status" == "RUNNING" ]; do
    sleep 10
    job_status=$(aws backup describe-backup-job --backup-job-id $job_id --region ${aws_region} |jq -r '.State')
done

cd $GITLAB_HOME
docker-compose up -d