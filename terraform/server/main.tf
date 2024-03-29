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
        vmid = 0
    }

    base_services = { for s in [
        { hostname = "pihole", specs = {}, network = { dns = "1.1.1.1" } },
        { hostname = "registry", specs = {}, network = { dns = "1.1.1.1" } },
    ]: s.hostname => s }

    other_services = { for s in [
        { hostname = "archmirror", specs = {}, network = {} },
        { hostname = "arr", specs = { disk_size = "2G" }, network = {} },
        { hostname = "jellyfin", specs = { disk_size = "3G" }, network = {} },
        { hostname = "letsencrypt", specs = { disk_size = "2G" }, network = {} },
        { hostname = "navidrome", specs = {}, network = {} },
        { hostname = "nfs", specs = {}, network = {} },
    ]: s.hostname => s }

    services = concat(values(local.base_services), values(local.other_services))
}

module "service_containers" {
    source = "./modules/service_containers"
    count = length(local.services)

    node = var.proxmox.node
    container = {
        hostname = local.services[count.index].hostname,
        ip = "${split("/", cidrhost(var.network.services_subnet, count.index + 1))[0]}/${local.mask_size}",
        storage = {
            path = var.storage.path,
            mountpoint = var.storage.mountpoint,
            size = var.storage.size,
        },
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
    filename = "../../tf-generated/pihole/service-hosts"
}


resource "local_file" "service_inventory" {
    content = templatefile(
        "templates/ansible-inventory.tftpl",
        {
            base_services = [
                for sc in module.service_containers.*:
                sc if can(local.base_services[sc.container.hostname])
            ]
            services = [
                for sc in module.service_containers.*:
                sc if can(local.other_services[sc.container.hostname])
            ]
            proxmox = var.proxmox
            network = var.network
            storage = var.storage
        }
    )
    filename = "../../tf-generated/ansible-services-inventory.ini"
}


resource "local_file" "pihole_setupVars" {
    content = templatefile(
        "templates/pihole-setupVars.conf.tftpl",
        {
            dhcp = var.dhcp
            network = var.network
        }
    )
    filename = "../../tf-generated/pihole/setupVars.conf"
}
