#!/bin/bash

# Move ssh service to port 2222

sudo echo "Port 2222" >> /etc/ssh/sshd_config
sudo echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/sshd_config

sudo systemctl restart sshd

echo "30 5 * * * /home/ubuntu/renew.sh" > mycron

if [ "${backups_enabled}" == "true" ]; then
    echo "0 6 * * * /home/ubuntu/backup.sh" >> mycron
fi

crontab -u root mycron
rm mycron

chown -R ubuntu:ubuntu /home/ubuntu