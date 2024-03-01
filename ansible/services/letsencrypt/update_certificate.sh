#!/bin/bash


function create-or-renew-certificate {
    local certbot_conf_dir="/etc/letsencrypt"

    [[ -f "${certbot_conf_dir}/live/{{ domain }}/fullchain.pem" ]] && {
        certbot renew
        exit 0
    }

    certbot certonly -a dns-multi \
        -c "${certbot_conf_dir}/certbot.ini" \
        --dns-multi-credentials "${certbot_conf_dir}/dns-multi.ini" \
        -d "*.{{ domain }}"
}


function main {
    create-or-renew-certificate
    sleep 12h
}


main
