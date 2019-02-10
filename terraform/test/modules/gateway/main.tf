
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
    _gateway_nat_ip = "${concat(google_compute_address.gateway-ephemeral-external.*.address,
                                google_compute_address.gateway-static-external.*.address)}"
}

// ref: https://www.terraform.io/docs/providers/google/d/datasource_compute_instance.html
resource "google_compute_instance" "gateway-instance" {
    name = "gateway-${var.env_uuid}-${count.index}"
    machine_type = "f1-micro"
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
