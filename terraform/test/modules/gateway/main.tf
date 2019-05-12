
variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

variable "public_subnetwork" {
    description = "The self-link of the public-facing subnetwork"
}

variable "private_subnetwork" {
    description = "The self-link of the private-facing subnetwork"
}

variable "admin_username" {
    description = "Username of the admin user"
}

variable "admin_sshkey" {
    description = "Ssh private-key contents for admin user"
}

variable "setup_data" {
    description = "Data to write into file passed as setup script parameter"
}

// Ref: https://www.terraform.io/docs/providers/google/d/datasource_compute_subnetwork.html
data "google_compute_subnetwork" "public" {
    name = "${var.public_subnetwork}"
}

data "google_compute_subnetwork" "private" {
    name = "${var.private_subnetwork}"
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_address.html
resource "google_compute_address" "gateway-ephemeral-external" {
    name = "gateway-external-${var.env_uuid}-${count.index}"
    address_type = "EXTERNAL"
    description = "Ephemeral external address for test gateway"
    network_tier = "STANDARD"
    count = "${var.env_name == "test" ? 1 : 0}"
}

resource "google_compute_address" "gateway-static-external" {
    name = "gateway-external-${var.env_uuid}-${count.index}"
    address_type = "EXTERNAL"
    description = "Static external address for production and staging gateway"
    network_tier = "${var.env_name == "prod" ? "PREMIUM" : "STANDARD"}"  // save a little money
    count = "${var.env_name != "test" ? 1 : 0}"  // use gateway-ephemeral-ext for test
}

resource "google_compute_address" "gateway" {
    count = 2  // 0: public subnet;  1: private subnet
    name = "gateway-internal-${var.env_uuid}-${count.index}"
    address_type = "INTERNAL"
    subnetwork = "${count.index == 0
                    ? data.google_compute_subnetwork.public.name
                    : data.google_compute_subnetwork.private.name}"
    description = "Static internal addresses for gateway instance"
    lifecycle {
        ignore_changes = ["subnetwork"]
    }
}

locals {
    c = ":"  // illegal character
    _gateway_nat_ip = "${concat(google_compute_address.gateway-ephemeral-external.*.address,
                                google_compute_address.gateway-static-external.*.address)}"
    _script_filepath = "/var/tmp/setup.sh"
    _data_filepath = "/var/tmp/setup.data"
}

// ref: https://www.terraform.io/docs/providers/google/d/datasource_compute_instance.html
resource "google_compute_instance" "gateway-instance" {
    name = "gateway-${var.env_uuid}-${count.index}"
    machine_type = "n1-standard-1"
    count = 1
    description = "Gateway system for managing/routing traffic in/out of VPC"
    boot_disk {
        auto_delete = "true"
        initialize_params {
            size = 200
            image = "centos-7"
        }
    }
    can_ip_forward = "true"
    network_interface {
        subnetwork = "${data.google_compute_subnetwork.public.self_link}"
        network_ip = "${google_compute_address.gateway.0.address}"
        access_config {
            nat_ip = "${element(local._gateway_nat_ip, 0)}"
            network_tier = "${var.env_name == "prod" ? "PREMIUM" : "STANDARD"}"
        }
    }
    network_interface {
        subnetwork = "${data.google_compute_subnetwork.private.self_link}"
        network_ip = "${google_compute_address.gateway.1.address}"
        // N/B: must *NOT* have an access_config block to prevent NAT address assignment
    }

    connection {
        type = "ssh"
        host = "${element(local._gateway_nat_ip, 0)}"
        user = "${var.admin_username}"
        private_key = "${var.admin_sshkey}"
    }

    provisioner "file" {
        destination = "${local._script_filepath}"
        content = "${file("${path.module}/setup.sh")}"
    }

    provisioner "file" {
        destination = "${local._data_filepath}"
        content = "${var.setup_data}"
    }

    provisioner "remote-exec" {
        inline = ["/bin/bash ${local._script_filepath} ${local._data_filepath}"]
    }
}

output "self_link" {
    value = "google_compute_instance.gateway-instance.self_link}"
    sensitive = true
}

output "external_ip" {
    value = "${google_compute_instance.gateway-instance.network_interface.0.access_config.0.nat_ip}"
    sensitive = true
}

output "private_ip" {
    value = "${google_compute_instance.gateway-instance.network_interface.1.network_ip}"
    sensitive = true
}
