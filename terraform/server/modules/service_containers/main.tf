terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

resource "proxmox_lxc" "service_container" {
    target_node = var.node
    hostname = var.container.hostname

    password = var.secrets.root_password
    ssh_public_keys = "${file(var.secrets.ssh_pub_key)}"

    ostemplate = "local:vztmpl/alpine-3.18-ssh_20240225_amd64.tar.xz"

    start = true
    onboot = true
    unprivileged = false

    cores = var.specs.cores
    memory = var.specs.memory
    swap = var.specs.swap

    vmid = var.specs.vmid

    features {
        nesting = true
    }

    rootfs {
        storage = "local-lvm"
        size = var.specs.disk_size
    }

    mountpoint {
        slot = "0"
        key = 0
        storage = var.container.storage.path
        volume = var.container.storage.path
        mp = var.container.storage.mountpoint
        size = var.container.storage.size
    }

    network {
        name = "eth0"
        bridge = "vmbr0"
        ip = var.container.ip
        gw = var.network.gateway
    }
    nameserver = var.network.dns

    tags = "terraform"
}
