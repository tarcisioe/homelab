#!/bin/bash
set -eou pipefail

function get-release() {
    grep 'release' "${1}" | cut -d ':' -f 2 | sed -e 's/\(\s*"\|"\s*\)//g'
}

function main() {
    local release
    local date
    local yaml="alpine_lxc_base.yml"

    release="$(get-release "${yaml}")"
    date="$(date +%Y%m%d)"

    sudo distrobuilder build-lxc alpine_lxc_base.yml image
    sudo chown "${USER}:${USER}" -R image
    rm image/meta.tar.xz
    mv image/rootfs.tar.xz image/"alpine-${release}-homelab_${date}_amd64.tar.xz"
}

main
