#!/bin/bash
apt-get update
apt-get install docker.io docker-compose s3fs awscli -y
usermod -aG docker ubuntu

read -r -d '' DAEMON_JSON << EOM
{
  "bip": "${docker_cidr}"
}
EOM

sudo echo "$DAEMON_JSON" > /etc/docker/daemon.json

sudo service docker restart

mkdir /gitlab

s3fs ${s3_bucket} /gitlab -o allow_other -o iam_role="auto" -o url="https://s3.${aws_region}.amazonaws.com"
cd /gitlab
chown -R ubuntu:ubuntu /gitlab
export GITLAB_HOME=/gitlab
docker-compose up -d 
