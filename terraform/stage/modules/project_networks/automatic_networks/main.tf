variable "project_id" {
    description = "The ID of the project to create network for"
    default = ""
}

locals {
    default = "default"
    default_in = "default_in"
    default_out = "default_out"
    testname = "default-${var.project_id}"
    testname_in = "default-in-${var.project_id}"
    testname_out = "default-out-${var.project_id}"
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "automatic" {
    count = "${var.project_id != "" ? 1 : 0}"
    name = "${var.project_id == "test"
              ? local.testname
              : local.default}"
    description = "Auto-allocated network for general use"
    auto_create_subnetworks = "true"
    project = "${var.project_id}"
}

resource "google_compute_firewall" "automatic-out" {
    count = "${var.project_id != "" ? 1 : 0}"
    name = "${var.project_id == "test"
              ? local.testname_out
              : local.default_out}"
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
    name = "${var.project_id == "test"
              ? local.testname_in
              : local.default_in}"
    network = "${google_compute_network.automatic.self_link}"
    direction = "INGRESS"
    project = "${var.project_id}"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["22"] }
    allow { protocol = "udp" ports = ["22"] }
}

output "name" {
    value = "${var.project_id == "test"
             ? local.testname
             : local.default}"
}
