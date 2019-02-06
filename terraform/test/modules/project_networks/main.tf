
variable "default_tcp_ports" {
    type = "list"
    description = "List of TCP ports or port-ranges to permit through default network firewall"
    default = ["22"]  // empty means allow-all
}

variable "default_udp_ports" {
    type = "list"
    description = "List of UDP ports or port-ranges to permit through default network firewall"
    default = ["22"]  // empty means allow-all
}

variable "private_cidr" {
    description = "CIDR to use for internal/private network subnet"
}

variable "public_cidr" {
    description = "CIDR to use for public/default network subnet"
}

/**** PUBLIC ****/

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "default" {
    name = "default"
    description = "Public-facing network with external IPs and google managed firewall"
    auto_create_subnetworks = "false"
}

// Ref: https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "default" {
    name = "default"
    ip_cidr_range = "${var.public_cidr}"
    network = "${google_compute_network.default.self_link}"
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_firewall.html
resource "google_compute_firewall" "default-in" {
    name    = "default-in"
    network = "${google_compute_network.default.self_link}"
    direction = "INGRESS"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["${var.default_tcp_ports}"] }
    allow { protocol = "udp" ports = ["${var.default_udp_ports}"] }
}

resource "google_compute_firewall" "default-out" {
    name    = "default-out"
    network = "${google_compute_network.default.self_link}"
    direction = "EGRESS"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "icmp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
    allow { protocol = "esp" }
    allow { protocol = "ah" }
    allow { protocol = "sctp" }
}

/**** PRIVATE ****/

resource "google_compute_network" "private" {
    name = "private"
    description = "Private inter-instance network for internal use."
    auto_create_subnetworks = "false"
}

// Ref: https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "private" {
    name = "private"
    ip_cidr_range = "${var.private_cidr}"
    network = "${google_compute_network.private.self_link}"
    private_ip_google_access = "true"  // Allow access to google APIs
}

resource "google_compute_firewall" "private-allow-in" {
    name    = "private-allow-in"
    network = "${google_compute_network.private.self_link}"
    direction = "INGRESS"

    source_ranges = ["${var.private_cidr}"]

    allow { protocol = "icmp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
    allow { protocol = "esp" }
    allow { protocol = "ah" }
    allow { protocol = "sctp" }
}

resource "google_compute_firewall" "private-allow-out" {
    name    = "private-allow-out"
    network = "${google_compute_network.private.self_link}"
    direction = "EGRESS"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "icmp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
    allow { protocol = "esp" }
    allow { protocol = "ah" }
    allow { protocol = "sctp" }
}

output "public" {
    value = {
        network_name = "${google_compute_network.default.name}"
        network_link = "${google_compute_network.default.self_link}"
        subnetwork_name = "${google_compute_subnetwork.default.name}"
        subnetwork_link = "${google_compute_subnetwork.default.self_link}"
    }
    sensitive = true
}

output "private" {
    value = {
        network_name = "${google_compute_network.private.name}"
        network_link = "${google_compute_network.private.self_link}"
        subnetwork_name = "${google_compute_subnetwork.private.name}"
        subnetwork_link = "${google_compute_subnetwork.private.self_link}"
    }
    sensitive = true
}
