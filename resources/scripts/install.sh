#!/bin/bash

apt-get update
apt-get install jq docker.io docker-compose awscli python3-certbot -y

if [ "${dns_provider}" == "route53" ]; then
    apt-get install python3-certbot-dns-route53 -y
    certbot certonly --non-interactive --agree-tos --email ${certbot_email} --no-redirect --dns-route53 -d ${host_domain}
elif [ "${dns_provider}" == "cloudflare" ]; then
    apt-get install python3-certbot-dns-cloudflare -y

    mkdir -p /root/.secrets/certbot

    TOKEN=$(aws ssm get-parameter \
        --name "${cloudflare_api_token_ssm_parameter_name}" \
        --with-decryption \
        --region "${aws_region}" \
        --query Parameter.Value \
        --output text)

    printf "dns_cloudflare_api_token = %s\n" "$TOKEN" > /root/.secrets/certbot/cloudflare.ini
    unset TOKEN
    chmod 600 /root/.secrets/certbot/cloudflare.ini


    certbot certonly --non-interactive --agree-tos --email ${certbot_email} --no-redirect \
        --dns-cloudflare \
        --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
        -d ${host_domain}
else
    echo "Unsupported dns_provider: ${dns_provider}"
    exit 1
fi

usermod -aG docker ubuntu
service docker restart

GITLAB_DEVICE="/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${gitlab_volume_id}"
SWAP_DEVICE="/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${swap_volume_id}"

for i in {1..30}; do
    if [ -e "$GITLAB_DEVICE" ] && [ -e "$SWAP_DEVICE" ]; then
        break
    fi
    sleep 2
done

if [ ! -e "$GITLAB_DEVICE" ] || [ ! -e "$SWAP_DEVICE" ]; then
    echo "GitLab or swap EBS device did not appear" >&2
    exit 1
fi

mkswap "$SWAP_DEVICE"
swapon "$SWAP_DEVICE"
SWAP_UUID=$(blkid -s UUID -o value "$SWAP_DEVICE")
echo "UUID=$SWAP_UUID none swap sw,nofail 0 0" >> /etc/fstab



export GITLAB_HOME="/srv/gitlab"

echo "export GITLAB_HOME=$GITLAB_HOME" >> /home/ubuntu/.profile
echo "export GITLAB_HOME=$GITLAB_HOME" >> /root/.bashrc

if [ "${make_fs}" == "true" ]; then
    mkfs -t xfs "$GITLAB_DEVICE"
fi

mkdir -p $GITLAB_HOME
chown root:root $GITLAB_HOME
mount "$GITLAB_DEVICE" $GITLAB_HOME
FS_UUID=$(blkid -s UUID -o value "$GITLAB_DEVICE")

echo "UUID=$FS_UUID $GITLAB_HOME xfs defaults,nofail 0 2" >> /etc/fstab

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
