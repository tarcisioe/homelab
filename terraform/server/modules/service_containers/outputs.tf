output "container" {
    value = {
        hostname = proxmox_lxc.service_container.hostname
        ip = split("/", proxmox_lxc.service_container.network[0].ip)[0]
        node = split("/", proxmox_lxc.service_container.id)[0]
        vmid = split("/", proxmox_lxc.service_container.id)[2]
    }
}
