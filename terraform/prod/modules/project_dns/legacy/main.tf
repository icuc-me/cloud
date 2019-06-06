
provider "google" {}

variable "legacy_domains" {
    description = "List of complete legacy FQDNs to manage"
    type = "list"
}

variable "domain_zone" {
    description = "Zone of primary domain to use when glue_count != 0."
}

variable "glue_count" {
    description = "Zero, or the number of legacy_domains to add glue records for in domain_zone."
}

variable "env_uuid" {
    description = "Environment name and uuid managing these resources"
}

locals {
    d = "."
    h = "-"
}

data "google_client_config" "domain" {}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "legacy" {
    count = "${length(var.legacy_domains)}"
    name = "${replace(var.legacy_domains[count.index], local.d, local.h)}"
    dns_name = "${var.legacy_domains[count.index]}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid} for project ${data.google_client_config.domain.project}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    count = "${var.glue_count}"
    managed_zone = "${var.domain_zone}"
    name = "${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.legacy.*.name_servers[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

data "template_file" "shortnames" {
    count = "${length(google_dns_managed_zone.legacy.*.dns_name)}"
    template = "${element(split(local.d,
                                google_dns_managed_zone.legacy.*.dns_name[count.index]),
                          0)}"
}

data "template_file" "fqdns" {
    count = "${length(google_dns_managed_zone.legacy.*.dns_name)}"
    template = "${substr(google_dns_managed_zone.legacy.*.dns_name[count.index],
                         0,
                         length(google_dns_managed_zone.legacy.*.dns_name[count.index]) - 1)}"
}

output "name_to_zone" {
    value = "${zipmap(data.template_file.shortnames.*.rendered,
                      google_dns_managed_zone.legacy.*.name)}"
    sensitive = true
}

output "name_to_ns" {
    value = "${zipmap(data.template_file.shortnames.*.rendered,
                      google_dns_managed_zone.legacy.*.name_servers)}"
    sensitive = true
}

output "name_to_fqdn" {
    value = "${zipmap(data.template_file.shortnames.*.rendered,
                      data.template_file.fqdns.*.rendered)}"
    sensitive = true
}
