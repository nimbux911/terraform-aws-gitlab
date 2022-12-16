#!/bin/bash

# Move ssh service to port 2222

apt-get update
apt-get install ansible ansible-core

echo "Port 2222" >> /etc/ssh/sshd_config
echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/sshd_config

systemctl restart sshd

export GITLAB_HOME="/home/ubuntu/gitlab"

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

if [ "${backups_enabled}" == "true" ]; then
    echo "0 6 * * * /home/ubuntu/backup.sh" > mycron
fi

crontab -u root mycron
rm mycron

chown -R ubuntu:ubuntu /home/ubuntu

cd $GITLAB_HOME
docker-compose down
docker-compose up -d 