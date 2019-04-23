
provider "google" {}

variable "domain" {
    description = "Complete base fqdn to build out"
}

variable "cloud_subdomain" {
    description = "subdomain for google cloud resources"
}

variable "site_subdomain" {
    description = "subdomain of for non-cloud resources"
}

locals {
    d = "."
    h = "-"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "base_fqdn" {
    provider = "google.base"
    name = "${replace(var.domain, local.d, local.h)}"
    dns_name = "${var.domain}."
    visibility = "public"  # N/B: only actual when registrar points at assigned NS
}

locals {
    fqdn = "${substr(google_dns_managed_zone.base_fqdn.dns_name,
                     0, length(google_dns_managed_zone.base_fqdn.dns_name) - 1)}"
}

module "cloud" {
    source = "../sub"
    providers = {
        google.base = "google"
        google.sub = "google"
    }
    base_fqdn = "${local.fqdn}"
    base_name = "${google_dns_managed_zone.base_fqdn.name}"
    subdomain = "${var.cloud_subdomain}"
}

module "site" {
    source = "../sub"
    providers = {
        google.base = "google"
        google.sub = "google"
    }
    base_fqdn = "${local.fqdn}"
    base_name = "${google_dns_managed_zone.base_fqdn.name}"
    subdomain = "${var.site_subdomain}"
}

output "fqdn_names" {
    value = "${merge(map(local.fqdn, google_dns_managed_zone.base_fqdn.name),
                     module.cloud.fqdn_name,
                     module.site.fqdn_name)}"
    sensitive = true
}

output "fqdn_ns" {
    value = ["${google_dns_managed_zone.base_fqdn.name_servers}"]
    sensitive = true
}
