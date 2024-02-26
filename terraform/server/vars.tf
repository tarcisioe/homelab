variable "proxmox" {
    type = object({
        ip = string,
        port = number,
        node = string,
    })
}

variable "secrets" {
    type = object({
        ssh_pub_key = string,
        root_password = string,
        proxmox = object({
            user = string,
            password = string,
        })
    })
}

variable "network" {
    type = object({
        subnet = string,
        services_subnet = string,
        gateway = string,
        dns = string,
        domain = string,
    })
}

variable "dhcp" {
    type = object({
        start = string,
        end = string,
        router = string,
    })
}
