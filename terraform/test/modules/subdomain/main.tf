
provider "google" {
    alias = "domain"   // provider owning the 'domain'
}

provider "google" {
    alias = "subdomain"  // provider owning the 'subdomain'
}

variable "mx_fqdn" {
    description = "FQDN to use in MX record"
}

variable "glue_zone" {
    description = "Zone name managed by google.domain to contain glue record, and MX destination"
}

variable "subdomain_fqdn" {
    description = "Subdomain fqdn to create"
}

variable "description" {
    description = "Managing environment name and UUID."
}

locals {
    d = "."
    h = "-"
    // remove trailing dot to make value easier to work with
    subdomain_zone = "${replace(substr(var.subdomain_fqdn, 0, length(var.subdomain_fqdn) - 1),
                                local.d,
                                local.h)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "subdomain" {
    provider = "google.subdomain"
    name = "${local.subdomain_zone}"
    dns_name = "${var.subdomain_fqdn}"
    visibility = "public"
    description = "${var.description}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    provider = "google.domain"
    managed_zone = "${var.glue_zone}"
    name = "${google_dns_managed_zone.subdomain.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.subdomain.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "mx" {
    provider = "google.subdomain"
    managed_zone = "${google_dns_managed_zone.subdomain.name}"
    name = "${google_dns_managed_zone.subdomain.dns_name}"
    type = "MX"
    rrdatas = ["10 ${var.mx_fqdn}"]
    ttl = "${60 * 60 * 24}"
}

output "common_fqdn" {
    value = "${substr(google_dns_record_set.glue.name,
                      0,
                      length(google_dns_record_set.glue.name) - 1)}"
    sensitive = true
}

output "fqdn" {
    value = "${google_dns_record_set.glue.name}"
    sensitive = true
}

output "zone" {
    value = "${google_dns_managed_zone.subdomain.name}"
    sensitive = true
}
