
provider "google" {}

variable "legacy_domains" {
    description = "List of legacy FQDNs to manage with CNAMES into var.dest_domain"
    type = "list"
}

variable "dest_domain" {
    description = "FQDN for legacy domain's to point at"
}

variable "env_uuid" {
    description = "Environment name and uuid managing these resources"
}

locals {
    d = "."
    h = "-"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "legacy" {
    count = "${length(var.legacy_domains)}"
    name = "${replace(var.legacy_domains[count.index], local.d, local.h)}"
    dns_name = "${var.legacy_domains[count.index]}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid}"
}

data "template_file" "shortnames" {
    count = "${length(var.legacy_domains)}"
    template = "${element(split(local.d,
                                google_dns_managed_zone.legacy.*.dns_name[count.index]),
                          0)}"
}

output "name_to_zone" {
    value = "${zipmap(data.template_file.shortnames.*.rendered,
                      google_dns_managed_zone.legacy.*.name)}"
    sensitive = true
}

output "name_to_nameservers" {
    value = "${zipmap(data.template_file.shortnames.*.rendered,
               google_dns_managed_zone.legacy.*.name_servers)}"
    sensitive = true
}
