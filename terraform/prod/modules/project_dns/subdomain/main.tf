
/*
Create this structure:

    subdomain.example.com  "${subdomain}"   - assumed to not exist
       |
       +----- ...records...

    and

    example.com  "${domain}"   - assumed to already exist
        |
        +-----subdomain.example.com (NS) ---> nameservers

    Where creation of all leaf nodes (except glue record) are all optional.

Output: A dictionary with ${subdomain} as key and managed zone name as value.
*/

provider "google" {
    alias = "domain"   // provider owning the 'domain'
}

provider "google" {
    alias = "subdomain"  // provider owning the 'subdomain'
}

variable "glue_zone" {
    description = "Optional, zone name managed by google.domain to contain glue record"
    default = ""
}

variable "subdomain_fqdn" {
    description = "Subdomain fqdn to create"
}

variable "env_uuid" {
    description = "Managing environment name and UUID."
}

/*****/

data "google_client_config" "subdomain" { provider = "google.subdomain" }

locals {
    d = "."
    h = "-"
    // remove trailing dot to make value easier to work with
    subdomain_zone = "${replace(var.subdomain_fqdn, local.d, local.h)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "subdomain" {
    provider = "google.subdomain"
    name = "${local.subdomain_zone}"
    dns_name = "${var.subdomain_fqdn}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid} for project ${data.google_client_config.subdomain.project}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    count = "${var.glue_zone != "" ? 1 : 0}"
    provider = "google.domain"
    managed_zone = "${var.glue_zone}"
    name = "${google_dns_managed_zone.subdomain.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.subdomain.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

output "name_to_zone" {
    // short-name to zone-name
    value = "${map(element(split(local.d, google_dns_managed_zone.subdomain.dns_name), 0),
                   google_dns_managed_zone.subdomain.name)}"
    sensitive = true
}
