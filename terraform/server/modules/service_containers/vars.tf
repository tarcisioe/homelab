variable "node" {
    type = string
    nullable = false
}

variable "container" {
    type = object({
        hostname = string,
        ip = string,
    })
}

variable "secrets" {
    type = object({
        ssh_pub_key = string,
        root_password = string,
    })
}

variable "network" {
    type = object({
        gateway = string,
        dns = string,
    })
}

variable "specs" {
    type = object({
        cores = number,
        memory = number,
        disk_size = string,
        swap = number,
    })
}
