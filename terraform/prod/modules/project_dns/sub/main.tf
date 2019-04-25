
provider "google" {
    alias = "base"   // provider owning the 'domain' (below)
}

variable "domain" {
    description = "Right-most base dns name containing the subdomain"
}

variable "base_zone" {
    description = "Right-most managed zone name of domain"
}


provider "google" {
    alias = "subdomain"  // provider owning the 'subdomain' (below)
}

variable "subdomain" {
    description = "left-most dns name of the subdomain"
}

variable "project" {
    description = "Name of project managing these resources"
}

locals {
    d = "."
    h = "-"
    fqdn = "${var.subdomain}.${var.domain}"
    name = "${replace(local.fqdn, local.d, local.h)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "sub" {
    provider = "google.subdomain"
    name = "${local.name}"
    dns_name = "${local.fqdn}."
    visibility = "public"
    description = "Managed by terraform from project ${var.project}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    provider = "google.base"
    managed_zone = "${var.base_zone}"
    name = "${google_dns_managed_zone.sub.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.sub.name_servers}"]
    ttl = 86400
}

output "name_to_zone" {
    // short-name to zone-name
    value = "${map(var.subdomain, google_dns_managed_zone.sub.name)}"
    sensitive = true
}
