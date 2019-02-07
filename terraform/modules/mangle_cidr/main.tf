variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

variable "private_cidr" {
    description = "CIDR to use for internal/private network subnet"
}

variable "public_cidr" {
    description = "CIDR to use for public/default network subnet"
}

data "external" "mangled_cidr" {
    count = 2
    program = ["python3", "${path.module}/unrandom_cidr.py"]
    query = {
        seed_string = "${var.env_uuid}_${var.env_name}_${count.index == 0
                                                         ? var.private_cidr
                                                         : var.public_cidr}"
    }
}

locals {
    mangled_private = "${data.external.mangled_cidr.0.result["cidr"]}"
    mangled_public = "${data.external.mangled_cidr.1.result["cidr"]}"
}

output "private_cidr" {
    value = "${var.env_name == "test"
               ? local.mangled_private
               : var.private_cidr}"
    sensitive = true
}

output "public_cidr" {
    value = "${var.env_name == "test"
               ? local.mangled_public
               : var.public_cidr}"
    sensitive = true
}
