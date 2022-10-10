#!/bin/bash

apt-get update
apt-get install jq docker.io docker-compose awscli python3-certbot python3-certbot-dns-route53 -y
usermod -aG docker ubuntu
service docker restart

certbot certonly --non-interactive --agree-tos --email ${certbot_email} --no-redirect --dns-route53 -d ${host_domain}

export GITLAB_HOME="/srv/gitlab"

echo "export GITLAB_HOME=$GITLAB_HOME" >> /home/ubuntu/.profile
echo "export GITLAB_HOME=$GITLAB_HOME" >> /root/.bashrc

DEVICE=/dev/$(lsblk -J | jq -r '.blockdevices[] | select(.type | index("disk")) | select(has("children") | not) | select(.mountpoints | index(null)).name')
if [ "${make_fs}" == "true" ]; then
    mkfs -t xfs $DEVICE
fi

mkdir $GITLAB_HOME
chown root:root $GITLAB_HOME
mount $DEVICE $GITLAB_HOME
FS_UUID=$(blkid |grep "$DEVICE" | awk '{print $2}')

echo "$FS_UUID $GITLAB_HOME xfs  defaults,nofail 0 2" >> /etc/fstab

umount $GITLAB_HOME
mount -a

if [ ! -f $GITLAB_HOME/config/ssl/${host_domain}.crt ]; then
    mkdir -p $GITLAB_HOME/config/ssl
    chmod 755 $GITLAB_HOME/config/ssl
    cp /etc/letsencrypt/live/${host_domain}/fullchain.pem $GITLAB_HOME/config/ssl/${host_domain}.crt
    cp /etc/letsencrypt/live/${host_domain}/privkey.pem $GITLAB_HOME/config/ssl/${host_domain}.key
fi

echo "30 5 * * * /home/ubuntu/renew.sh" > mycron

if [ "${backups_enabled}" == "true" ]; then
    echo "0 6 * * * /home/ubuntu/backup.sh" >> mycron
fi

crontab -u root mycron
rm mycron

if [ ! -f $GITLAB_HOME/docker-compose.yml ]; then
    cp /home/ubuntu/docker-compose.yml $GITLAB_HOME
fi

chown -R ubuntu:ubuntu /home/ubuntu

cd $GITLAB_HOME
docker-compose up -d 