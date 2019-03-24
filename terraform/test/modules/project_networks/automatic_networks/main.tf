variable "project_id" {
    description = "The ID of the project to create network for"
    default = ""
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "automatic" {
    count = "${var.project_id != "" ? 1 : 0}"
    name = "automatic-${var.project_id}"
    description = "Auto-allocated network for general use"
    auto_create_subnetworks = "true"
    project = "${var.project_id}"
}

resource "google_compute_firewall" "automatic-out" {
    count = "${var.project_id != "" ? 1 : 0}"
    name    = "automatic-${var.project_id}-out"
    network = "${google_compute_network.automatic.self_link}"
    direction = "EGRESS"
    project = "${var.project_id}"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "ah" }
    allow { protocol = "esp" }
    allow { protocol = "icmp" }
    allow { protocol = "sctp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
}

resource "google_compute_firewall" "automatic-in" {
    count = "${var.project_id != "" ? 1 : 0}"
    name    = "automatic-${var.project_id}-in"
    network = "${google_compute_network.automatic.self_link}"
    direction = "INGRESS"
    project = "${var.project_id}"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["22"] }
    allow { protocol = "udp" ports = ["22"] }
}

output "name" {
    value = "automatic-${var.project_id}"
}
