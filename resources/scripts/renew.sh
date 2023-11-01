#!/bin/bash

export GITLAB_HOME="/srv/gitlab"

m1=$(md5sum "/etc/letsencrypt/live/${host_domain}/fullchain.pem" | awk '{print $1}')
m2=$(md5sum "$GITLAB_HOME/config/ssl/${host_domain}.crt" | awk '{print $1}')

if [ "$m1" != "$m2" ]; then
    cp /etc/letsencrypt/live/${host_domain}/fullchain.pem $GITLAB_HOME/config/ssl/${host_domain}.crt
    cp /etc/letsencrypt/live/${host_domain}/privkey.pem $GITLAB_HOME/config/ssl/${host_domain}.key
    docker exec ${gitlab_container_name} gitlab-ctl restart nginx
fi