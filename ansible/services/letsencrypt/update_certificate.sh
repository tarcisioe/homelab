#!/bin/bash

set -euo pipefail

DOMAIN="{{ domain }}"
CERTBOT_CONF_DIR="/etc/letsencrypt"
DOMAIN_CERTS_DIR="${CERTBOT_CONF_DIR}/live/${DOMAIN}"


function create-or-renew-certificate {
    [[ -f "${DOMAIN_CERTS_DIR}/fullchain.pem" ]] && {
        certbot renew
        return 0
    }

    certbot certonly -a dns-multi \
        --dns-multi-credentials "${CERTBOT_CONF_DIR}/dns-multi.ini" \
        -d "*.{{ domain }}"
}


function ensure-certs-on-output {
    echo "Copying certs to output"
    cp "${DOMAIN_CERTS_DIR}"/* /certs
}


function main {
    create-or-renew-certificate &&
    ensure-certs-on-output &&
    sleep 12h
}


main
