variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

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

data "google_compute_regions" "available" {}

data "google_client_config" "current" {}

data "template_file" "exclude_regions" {
    count = "${local.nr_regions}"
    template = "${replace(local.regions[count.index], local.include_re, "")}"
}

locals {
    regions = ["${sort(compact(data.google_compute_regions.available.names))}"]
    nr_regions = "${length(local.regions)}"
    include_re = "/us-.+/"
    filtered_regions = "${matchkeys(local.regions,
                                    data.template_file.exclude_regions.*.rendered,
                                    list(""))}"
    nr_filtered_regions = "${length(local.filtered_regions)}"
}

module "subnet_cidrs" {
    source = "./subnet_cidrs"
    count = "${local.nr_filtered_regions * 2}"
    env_uuid = "${var.env_uuid}"
}

/**** PUBLIC ****/

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "default" {
    name = "default-${var.env_uuid}"
    description = "Public-facing network with external IPs and google managed firewall"
    auto_create_subnetworks = "false"
}

// Ref: https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "default" {
    count = "${local.nr_filtered_regions}"
    name = "default-${element(local.filtered_regions, count.index)}-${var.env_uuid}"
    region = "${element(local.filtered_regions, count.index)}"
    ip_cidr_range = "${element(module.subnet_cidrs.set, count.index)}"
    network = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"  // Allow access to google APIs
}

// possible not all resources were created
data "google_compute_subnetwork" "default" {
    count = "${local.nr_filtered_regions}"
    name = "${google_compute_subnetwork.default.*.name[count.index]}"
    region = "${google_compute_subnetwork.default.*.region[count.index]}"
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_firewall.html
resource "google_compute_firewall" "default-in" {
    name    = "default-in-${var.env_uuid}"
    network = "${google_compute_network.default.self_link}"
    direction = "INGRESS"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["${sort(var.default_tcp_ports)}"] }
    allow { protocol = "udp" ports = ["${sort(var.default_udp_ports)}"] }
}

resource "google_compute_firewall" "default-out" {
    name    = "default-out-${var.env_uuid}"
    network = "${google_compute_network.default.self_link}"
    direction = "EGRESS"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "ah" }
    allow { protocol = "esp" }
    allow { protocol = "icmp" }
    allow { protocol = "sctp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
}

/**** PRIVATE ****/

resource "google_compute_network" "private" {
    name = "private-${var.env_uuid}"
    description = "Private inter-instance network for internal use."
    auto_create_subnetworks = "false"
}

// Ref: https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "private" {
    count = "${local.nr_filtered_regions}"
    name = "private-${element(local.filtered_regions, count.index)}-${var.env_uuid}"
    region = "${element(local.filtered_regions, count.index)}"
    ip_cidr_range = "${element(module.subnet_cidrs.set, local.nr_filtered_regions + count.index)}"
    network = "${google_compute_network.private.self_link}"
    private_ip_google_access = "true"  // Allow access to google APIs
}

// possible not all resources were created
data "google_compute_subnetwork" "private" {
    count = "${local.nr_filtered_regions}"
    name = "${google_compute_subnetwork.private.*.name[count.index]}"
    region = "${google_compute_subnetwork.private.*.region[count.index]}"
}


resource "google_compute_firewall" "private-allow-in" {
    name    = "private-allow-in-${var.env_uuid}"
    network = "${google_compute_network.private.self_link}"
    direction = "INGRESS"

    // subnetwork cidr range definitions lifecycle ignored but rule must be correct
    source_ranges = ["${sort(data.google_compute_subnetwork.private.*.ip_cidr_range)}"]

    allow { protocol = "ah" }
    allow { protocol = "esp" }
    allow { protocol = "icmp" }
    allow { protocol = "sctp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
}

resource "google_compute_firewall" "private-allow-out" {
    name    = "private-allow-out-${var.env_uuid}"
    network = "${google_compute_network.private.self_link}"
    direction = "EGRESS"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "ah" }
    allow { protocol = "esp" }
    allow { protocol = "icmp" }
    allow { protocol = "sctp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
}

locals {
    actual_public_regions = ["${data.google_compute_subnetwork.default.*.region}"]
    actual_public_provider_region_idx = "${index(local.actual_public_regions,
                                                 data.google_client_config.current.region)}"

    actual_private_regions = ["${data.google_compute_subnetwork.private.*.region}"]
    actual_private_provider_region_idx = "${index(local.actual_private_regions,
                                                  data.google_client_config.current.region)}"
}

output "public" {
    value = {
        network_name = "${google_compute_network.default.name}"
        network_link = "${google_compute_network.default.self_link}"
        subnetwork_name = "${data.google_compute_subnetwork.default.*.name[local.actual_public_provider_region_idx]}"
        subnetwork_link = "${data.google_compute_subnetwork.default.*.self_link[local.actual_public_provider_region_idx]}"
    }
    sensitive = true
}

output "private" {
    value = {
        network_name = "${google_compute_network.private.name}"
        network_link = "${google_compute_network.private.self_link}"
        subnetwork_name = "${data.google_compute_subnetwork.private.*.name[local.actual_private_provider_region_idx]}"
        subnetwork_link = "${data.google_compute_subnetwork.private.*.self_link[local.actual_private_provider_region_idx]}"
    }
    sensitive = true
}
