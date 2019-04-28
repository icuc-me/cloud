
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

variable "legacy_domains" {
    description = "List of legacy FQDNs to manage with CNAMES into var.domain"
    type = "list"
}

variable "gateway" {
    description = "IP address of cloud gateway"
}

variable "project" {
    description = "Name of project managing these resources"
}

variable "env_name" {
    description = "Name of the current environment (test, stage, prod)"
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
    env_name = "${var.env_name}"
}

module "site_gateway" {
    source = "./myip"
}

module "site" {
    source = "./site"
    providers = { google = "google.prod" }
    domain = "${local.name}"
    zone = "${google_dns_managed_zone.domain.name}"
    site = "${var.site_subdomain}"
    gateway = "${module.site_gateway.ip}"
    project = "${var.project}"
}

module "legacy" {
    source = "./legacy"
    providers = { google = "google.prod" }
    legacy_domains = "${var.legacy_domains}"
    domain = "${local.name}"
    project = "${var.project}"
}

locals {
    name_to_zone = "${merge(map("fqdn", google_dns_managed_zone.domain.name),
                            module.cloud.name_to_zone,
                            module.site.name_to_zone)}"
}

output "name_to_zone" {
    value = "${local.name_to_zone}"
    sensitive = true
}

output "gateways" {
    value = {
        cloud = "${module.cloud.gateway}"
        site = "${module.site.gateway}"
    }
    sensitive = true
}

resource "google_dns_record_set" "mail" {
    managed_zone = "${local.name_to_zone["fqdn"]}"
    name = "mail.${google_dns_managed_zone.domain.dns_name}"
    type = "CNAME"
    rrdatas = ["${module.site.gateway}."]
    ttl = "300"
}

resource "google_dns_record_set" "domain_mx" {
    managed_zone = "${local.name_to_zone["fqdn"]}"
    name = "${google_dns_managed_zone.domain.dns_name}"
    type = "MX"
    rrdatas = ["10 mail.${google_dns_managed_zone.domain.dns_name}"]
    ttl = "300"
}

resource "google_dns_record_set" "home" {
    managed_zone = "${local.name_to_zone["fqdn"]}"
    name = "home.${google_dns_managed_zone.domain.dns_name}"
    type = "CNAME"
    rrdatas = ["${module.site.gateway}."]
    ttl = "300"
}

resource "google_dns_record_set" "www" {
    managed_zone = "${local.name_to_zone["fqdn"]}"
    name = "www.${google_dns_managed_zone.domain.dns_name}"
    type = "CNAME"
    rrdatas = ["${module.site.gateway}."]
    ttl = "300"
}
