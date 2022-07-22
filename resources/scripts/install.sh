#!/bin/bash

apt-get update
apt-get install docker.io docker-compose awscli python3-certbot python3-certbot-dns-route53 -y
usermod -aG docker ubuntu

sudo certbot certonly --non-interactive --agree-tos --email ${email} --no-redirect --dns-route53 -d ${dns}
sudo service docker restart
sudo mkswap /dev/nvme1n1
sudo swapon /dev/nvme1n1
sudo echo "/dev/nvme1n1 none swap sw 0 0" >> /etc/fstab

export GITLAB_HOME=/home/ubuntu/gitlab
chown -R ubuntu:ubuntu /home/ubuntu/gitlab

cd /home/ubuntu/gitlab
docker-compose up -d 
sudo mkdir -p /home/ubuntu/gitlab/config/ssl
sudo chmod 755 ssl
sudo cp /etc/letsencrypt/live/${dns}/fullchain.pem /home/ubuntu/gitlab/config/ssl/${dns}.crt
sudo cp /etc/letsencrypt/live/${dns}/privkey.pem /home/ubuntu/gitlab/config/ssl/${dns}.key