
provider "google" {}

variable "domain" {
    description = "FQDN of base domain name"
}

variable "zone" {
    description = "Managed zone name of domain"
}

variable "site" {
    description = "Name of site subdomain"
}

variable "gateway" {
    description = "IP address of gateway"
}

variable "project" {
    description = "Name of project managing these resources"
}

module "site" {
    source = "../sub"
    providers = {
        google.base = "google"
        google.subdomain = "google"
    }
    project = "${var.project}"
    domain = "${var.domain}"
    base_zone = "${var.zone}"
    subdomain = "${var.site}"
    create = "1"
}

locals {
    // add dependency on site module
    site_zone = "${module.site.name_to_zone[var.site]}"
}

resource "google_dns_record_set" "site_mx" {
    managed_zone = "${local.site_zone}"
    name = "${var.site}.${var.domain}."
    type = "MX"
    rrdatas = ["10 mail.${var.domain}."]
    ttl = "300"
}

resource "google_dns_record_set" "gateway" {
    managed_zone = "${local.site_zone}"
    name = "gateway.${var.site}.${var.domain}."
    type = "A"
    rrdatas = ["${var.gateway}"]
    ttl = "600"
}

output "name_to_zone" {
    value = "${map(var.site, local.site_zone)}"
    sensitive = true
}

output "gateway" {
    value = "${substr(google_dns_record_set.gateway.name,
                      0, length(google_dns_record_set.gateway.name) - 1)}"
    sensitive = true
}
