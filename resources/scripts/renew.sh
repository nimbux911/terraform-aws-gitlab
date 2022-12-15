#!/bin/bash

export GITLAB_HOME="/home/ubuntu/gitlab"

m1=$(md5sum "/etc/letsencrypt/live/${host_domain}/fullchain.pem")

certbot certonly --non-interactive --agree-tos --email ${certbot_email} --no-redirect --dns-route53 -d ${host_domain}

m2=$(md5sum "/etc/letsencrypt/live/${host_domain}/fullchain.pem")

if [ "$m1" != "$m2" ]; then
    cp /etc/letsencrypt/live/${host_domain}/fullchain.pem $GITLAB_HOME/config/ssl/${host_domain}.crt
    cp /etc/letsencrypt/live/${host_domain}/privkey.pem $GITLAB_HOME/config/ssl/${host_domain}.key
fi