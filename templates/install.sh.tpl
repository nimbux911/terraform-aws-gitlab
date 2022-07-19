#!/bin/bash

apt-get update
apt-get install docker.io docker-compose awscli -y
usermod -aG docker ubuntu

sudo service docker restart

export GITLAB_HOME=/home/ubuntu/gitlab
docker-compose up -d 
