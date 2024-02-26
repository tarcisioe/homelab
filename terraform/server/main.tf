terraform {
    backend "local" { }
    required_providers {
        proxmox = {
            source = "telmate/proxmox"
            version = "2.9.14"
        }
    }
}

provider "proxmox" {
    pm_api_url = "https://${var.proxmox.ip}:${var.proxmox.port}/api2/json"
    pm_tls_insecure = true

    pm_user = var.secrets.proxmox.user
    pm_password = var.secrets.proxmox.password

    pm_log_file = "terraform-plugin-proxmox.log"
    pm_debug = true
    pm_log_levels = {
        _default = "debug"
        _capturelog = ""
    }
}


locals {
    mask_size = split("/", var.network.subnet)[1]

    default_secrets = {
        ssh_pub_key = var.secrets.ssh_pub_key
        root_password = var.secrets.root_password
    }

    default_network = {
        gateway = var.network.gateway
        dns = var.network.dns
    }

    default_specs = {
        cores = 16
        memory = 2048
        disk_size = "1G"
        swap = 0
    }

    services = [
        { name = "pihole", specs = {}, network: { dns = "1.1.1.1" } },
    ]
}

module "service_containers" {
    source = "./modules/service_containers"
    count = length(local.services)

    node = var.proxmox.node
    container = {
        hostname = local.services[count.index].name,
        ip = "${split("/", cidrhost(var.network.services_subnet, count.index))[0]}/${local.mask_size}"
    }
    specs = merge(local.default_specs, local.services[count.index].specs)
    secrets = local.default_secrets
    network = merge(local.default_network, local.services[count.index].network)
}

resource "local_file" "pihole_server_hosts" {
    content = templatefile(
        "templates/hosts.tftpl",
        {
            services = module.service_containers.*
            domain = var.network.domain
        }
    )
    filename = "../../tf-generated/pihole-server-hosts"
}


resource "local_file" "service_inventory" {
    content = templatefile(
        "templates/inventory.tftpl",
        {
            services = module.service_containers.*
        }
    )
    filename = "../../tf-generated/services-inventory.ini"
}
