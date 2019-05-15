
/*
Create this structure:

    subdomain.example.com  "${subdomain}"
            |
            +-------(MX)
            |
            +-------mail
            |
            +-------www
            |
            +-------file
            |
            +-------gateway

    and

    example.com  "${domain}"
        |
        +-----subdomain.example.com (NS) ---> nameservers

    Where creation of all leaf nodes and the glue record are all optional.

Output: A dictionary with ${subdomain} as key and managed zone name as value.
*/

provider "google" {
    alias = "domain"   // provider owning the 'domain'
}

provider "google" {
    alias = "subdomain"  // provider owning the 'subdomain'
}

variable "domain_zone" {
    description = "Zone name in google.base to contain the glue record for subdomain"
}

variable "subdomain" {
    description = "Optional, subdomain shortname to create inside of domain_zone's fqdn"
    default = ""
}

variable "mx" {
    description = "Optional, list of rrdata for subdomain's MX record."
    type = "list"
    default = []
}

variable "mail" {
    description = "Optional, map of record type to rrdata for subdomain's 'mail' record."
    type = "map"
    default = {}
}

variable "www" {
    description = "Optional, map of record type to rrdata for subdomain's 'www' record."
    type = "map"
    default = {}
}

variable "file" {
    description = "Optional, map of record type to rrdata for subdomain's 'file' record."
    type = "map"
    default = {}
}

variable "gateway" {
    description = "Optional, map of record type to rrdata for subdomain's 'gateway' record."
    type = "map"
    default = {}
}

variable "env_uuid" {
    description = "Managing environment name and UUID."
}

/*****/

data "google_client_config" "domain" { provider = "google.domain" }

data "google_client_config" "subdomain" { provider = "google.subdomain" }

data "google_dns_managed_zone" "domain_zone" {
    provider = "google.domain"
    name = "${var.domain_zone}"
}

locals {
    d = "."
    h = "-"
    // remove trailing dot to make value easier to work with
    subdomain_fqdn = "${var.subdomain}.${substring(data.google_dns_managed_zone.dns_name,
                                                   0,
                                                   length(data.google_dns_managed_zone.dns_name))}"
    subdomain_zone = "${replace(local.subdomain_fqdn, local.d, local.h)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "subdomain" {
    count = "${var.subdomain != "" ? 1 : 0}"
    provider = "google.subdomain"
    name = "${local.subdomain_zone}"
    dns_name = "${local.subdomain_fqdn}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid} project {$data.google_client_config.domain.project} for project ${data.google_client_config.subdomain.project}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    count = "${var.subdomain != "" ? 1 : 0}"
    provider = "google.base"
    managed_zone = "${var.domain_zone}"
    name = "${local.subdomain_zone}."
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.subdomain.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "mx" {
    count = "${var.subdomain != "" && length(var.mx) != 0 ? 1 : 0}"
    provider = "google.subdomain"
    managed_zone = "${google_dns_managed_zone.subdomain.name}"  // guarantee dependency
    name = "${local.subdomain_fqdn}."
    type = "MX"
    rrdatas = ["${var.mx}"]
    ttl = "${60 * 60}"
}

output "name_to_zone" {
    // short-name to zone-name
    value = "${map(var.subdomain, google_dns_managed_zone.sub.name)}"
    sensitive = true
}
