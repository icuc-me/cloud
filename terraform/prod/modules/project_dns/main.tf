
provider "google" {
    alias = "test"
}

provider "google" {
    alias = "stage"
}

provider "google" {
    alias = "prod"
}

variable "domain" {
    description = "base DNS suffix to append to all managed zone names, e.g. 'example.com'"
}

variable "cloud_subdomain" {
    description = "subdomain for google cloud resources"
}

variable "site_subdomain" {
    description = "subdomain of for non-cloud resources"
}

variable "gateway" {
    description = "IP address of cloud gateway"
}

variable "project" {
    description = "Name of project managing these resources"
}

locals {
    d = "."
    h = "-"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "domain" {
    name = "${replace(var.domain, local.d, local.h)}"
    dns_name = "${var.domain}."
    visibility = "public"  # N/B: only actual when registrar points at assigned NS
    description = "Managed by terraform from project ${var.project}"
}

locals {
    // strip off trailing . & make dependent on resource
    name = "${substr(google_dns_managed_zone.domain.dns_name,
                     0, length(google_dns_managed_zone.domain.dns_name) - 1)}"
}

module "cloud" {
    source = "./cloud"
    providers = {
        google.test = "google.test"
        google.stage = "google.stage"
        google.prod = "google.prod"
    }
    domain = "${local.name}"
    zone = "${google_dns_managed_zone.domain.name}"
    cloud = "${var.cloud_subdomain}"
    gateway = "${var.gateway}"
    project = "${var.project}"
}


module "gateway" {
    source = "./myip"
}

module "site" {
    source = "./site"
    providers = { google = "google.prod" }
    domain = "${local.name}"
    zone = "${google_dns_managed_zone.domain.name}"
    site = "${var.site_subdomain}"
    gateway = "${module.gateway.ip}"
    project = "${var.project}"
}

output "fqdn" {
    value = "${local.name}"
}

output "zone" {
    value = "${google_dns_managed_zone.domain.name}"
}

output "ns" {
    value = ["${google_dns_managed_zone.domain.name_servers}"]
    sensitive = true
}

output "name_to_zone" {
    value = "${merge(map("fqdn", google_dns_managed_zone.domain.name),
                     module.cloud.name_to_zone,
                     module.site.name_to_zone)}"
    sensitive = true
}

output "gateways" {
    value = {
        cloud = "${module.cloud.gateway}"
        site = "${module.site.gateway}"
    }
    sensitive = true
}
