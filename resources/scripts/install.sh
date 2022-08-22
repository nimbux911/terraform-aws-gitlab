#!/bin/bash

# Move ssh service to port 2222

sudo echo "Port 2222" >> /etc/ssh/sshd_config
sudo echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/sshd_config

sudo systemctl restart sshd
