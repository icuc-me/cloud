
variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_address.html
resource "google_compute_address" "gateway-ephemeral-ext" {
    name = "gateway-ephemeral-${var.env_uuid}-0"
    address_type = "EXTERNAL"
    description = "Ephemeral external address for test gateway"
    network_tier = "STANDARD"
    count = "${var.env_name == "test" ? 1 : 0}"
}

resource "google_compute_address" "gateway-static-ext" {
    name = "gateway-external-${var.env_uuid}-0"
    address_type = "EXTERNAL"
    description = "Static external address for production and staging gateway"
    network_tier = "${var.env_name == "prod" ? "PREMIUM" : "STANDARD"}"  // save a little money
    count = "${var.env_name != "test" ? 1 : 0}"  // use gateway-ephemeral for test
}

// ref: https://www.terraform.io/docs/providers/google/d/datasource_compute_network.html
data "google_compute_network" "default" {
    name = "default"
}

resource "google_compute_address" "gateway-internal" {
    name = "gateway-internal-${var.env_uuid}-0"
    address_type = "INTERNAL"
    subnetwork = "${data.google_compute_network.default.self_link}"
    description = "Static internal address for gateway instance"
    lifecycle {
        ignore_changes = ["subnetwork"]
    }
}

locals {
    _gateway_nat_ip = "${concat(google_compute_address.gateway-ephemeral-ext.*.address,
                                google_compute_address.gateway-static-ext.*.address)}"
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
        network = "default"
        network_ip = "${google_compute_address.gateway-internal.0.address}"
        access_config {
            nat_ip = "${element(local._gateway_nat_ip, 0)}"
            network_tier = "${var.env_name == "prod" ? "PREMIUM" : "STANDARD"}"
        }
    }
}

output "internal-gateway-link" {
    value = "google_compute_instance.gateway-instance.self_link}"
    sensitive = true
}

output "external-gateway-ip" {
    value = "${google_compute_instance.gateway-instance.network_interface.0.access_config.0.nat_ip}"
    sensitive = true
}

output "internal-gateway-ip" {
    value = "${google_compute_instance.gateway-instance.network_interface.0.network_ip}"
    sensitive = true
}
