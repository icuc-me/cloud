variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

variable "test_project" {
    description = "The project ID for the test environment"
}

variable "public_tcp_ports" {
    type = "list"
    description = "List of TCP ports or port-ranges to permit through public network firewall"
    default = ["22"]  // empty means allow-all
}

variable "public_udp_ports" {
    type = "list"
    description = "List of UDP ports or port-ranges to permit through public network firewall"
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

/**** automatic ***/

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "automatic" {
    name = "automatic-${var.env_uuid}"
    description = "Auto-allocated network for general use"
    auto_create_subnetworks = "true"
    project = "${var.test_project}"
}

resource "google_compute_firewall" "automatic-out" {
    name    = "automatic-out-${var.env_uuid}"
    network = "${google_compute_network.automatic.self_link}"
    direction = "EGRESS"
    project = "${var.test_project}"

    destination_ranges = ["0.0.0.0/0"]

    allow { protocol = "ah" }
    allow { protocol = "esp" }
    allow { protocol = "icmp" }
    allow { protocol = "sctp" }
    allow { protocol = "tcp" }
    allow { protocol = "udp" }
}

resource "google_compute_firewall" "automatic-in" {
    name    = "automatic-in-${var.env_uuid}"
    network = "${google_compute_network.automatic.self_link}"
    direction = "INGRESS"
    project = "${var.test_project}"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["22"] }
    allow { protocol = "udp" ports = ["22"] }
}

/**** PUBLIC ****/

// ref: https://www.terraform.io/docs/providers/google/r/compute_network.html
resource "google_compute_network" "public" {
    name = "public-${var.env_uuid}"
    description = "Public-facing network with external IPs and google managed firewall"
    auto_create_subnetworks = "false"
}

// Ref: https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "public" {
    count = "${local.nr_filtered_regions}"
    name = "public-${element(local.filtered_regions, count.index)}-${var.env_uuid}"
    region = "${element(local.filtered_regions, count.index)}"
    ip_cidr_range = "${element(module.subnet_cidrs.set, count.index)}"
    network = "${google_compute_network.public.self_link}"
    private_ip_google_access = "true"  // Allow access to google APIs
}

// possible not all resources were created
data "google_compute_subnetwork" "public" {
    count = "${local.nr_filtered_regions}"
    name = "${google_compute_subnetwork.public.*.name[count.index]}"
    region = "${google_compute_subnetwork.public.*.region[count.index]}"
}

// ref: https://www.terraform.io/docs/providers/google/r/compute_firewall.html
resource "google_compute_firewall" "public-in" {
    name    = "public-in-${var.env_uuid}"
    network = "${google_compute_network.public.self_link}"
    direction = "INGRESS"

    allow { protocol = "icmp" }
    allow { protocol = "tcp" ports = ["${sort(var.public_tcp_ports)}"] }
    allow { protocol = "udp" ports = ["${sort(var.public_udp_ports)}"] }
}

resource "google_compute_firewall" "public-out" {
    name    = "public-out-${var.env_uuid}"
    network = "${google_compute_network.public.self_link}"
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
    actual_public_regions = ["${data.google_compute_subnetwork.public.*.region}"]
    actual_public_provider_region_idx = "${index(local.actual_public_regions,
                                                 data.google_client_config.current.region)}"

    actual_private_regions = ["${data.google_compute_subnetwork.private.*.region}"]
    actual_private_provider_region_idx = "${index(local.actual_private_regions,
                                                  data.google_client_config.current.region)}"
}

output "automatic" {
    value = {
        network_name = "${google_compute_network.automatic.name}"
        network_link = "${google_compute_network.automatic.self_link}"
    }
    sensitive = true
}

output "public" {
    value = {
        network_name = "${google_compute_network.public.name}"
        network_link = "${google_compute_network.public.self_link}"
        subnetwork_name = "${data.google_compute_subnetwork.public.*.name[local.actual_public_provider_region_idx]}"
        subnetwork_link = "${data.google_compute_subnetwork.public.*.self_link[local.actual_public_provider_region_idx]}"
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
