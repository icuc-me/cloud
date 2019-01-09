
// ref: https://www.terraform.io/docs/providers/google/r/compute_address.html
resource "google_compute_address" "gateway-ephemeral-ext" {
    name = "gateway-ephemeral-${var.UUID}-0"
    address_type = "EXTERNAL"
    description = "Ephemeral external address for test gateway"
    network_tier = "STANDARD"
    count = "${var.ENV_NAME == "test" ? 1 : 0}"
}

resource "google_compute_address" "gateway-static-ext" {
    name = "gateway-external-${var.UUID}-0"
    address_type = "EXTERNAL"
    description = "Static external address for production and staging gateway"
    network_tier = "${var.ENV_NAME == "prod" ? "PREMIUM" : "STANDARD"}"  // save a little money
    count = "${var.ENV_NAME != "test" ? 1 : 0}"  // use gateway-ephemeral for test
}

resource "google_compute_address" "gateway-internal" {
    name = "gateway-internal-${var.UUID}-0"
    address_type = "INTERNAL"
    description = "Static internal address for gateway instance"
}

locals {
    _gateway_nat_ip = "${concat(google_compute_address.gateway-ephemeral-ext.*.address,
                                google_compute_address.gateway-static-ext.*.address)}"
}

resource "google_compute_instance" "gateway-instance" {
    name = "gateway-${var.UUID}-${count.index}"
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
        network_ip = "${google_compute_address.gateway-internal.address}"
        access_config {
            nat_ip = "${element(local._gateway_nat_ip, 0)}"
            network_tier = "${var.ENV_NAME == "prod" ? "PREMIUM" : "STANDARD"}"
        }
    }
}
