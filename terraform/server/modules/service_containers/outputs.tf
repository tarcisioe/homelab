output "container" {
    value = {
        hostname = proxmox_lxc.service_container.hostname
        ip = split("/", proxmox_lxc.service_container.network[0].ip)[0]
    }
}
