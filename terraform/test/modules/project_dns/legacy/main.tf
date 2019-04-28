
provider "google" {}

variable "legacy_domains" {
    description = "List of legacy FQDNs to manage with CNAMES into var.domain"
    type = "list"
}

variable "domain" {
    description = "FQDN for legacy domain's to point at"
}

variable "project" {
    description = "Name of project managing these resources"
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
    description = "Managed by terraform from project ${var.project}"
}

data "template_file" "names" {
    count = "${length(var.legacy_domains)}"
    template = "${element(split(local.d,
                                google_dns_managed_zone.legacy.*.dns_name[count.index]),
                          0)}"
}

resource "google_dns_record_set" "mx" {
    count = "${length(var.legacy_domains)}"

    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "MX"
    rrdatas = ["10 mail.${var.domain}."]
    ttl = "3600"
}

resource "google_dns_record_set" "mail" {
    count = "${length(var.legacy_domains)}"

    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "mail.${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "CNAME"
    rrdatas = ["mail.${var.domain}."]
    ttl = "3600"
}

resource "google_dns_record_set" "www" {
    count = "${length(var.legacy_domains)}"

    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "www.${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "CNAME"
    rrdatas = ["www.${var.domain}."]
    ttl = "3600"
}

resource "google_dns_record_set" "home" {
    count = "${length(var.legacy_domains)}"

    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "home.${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "CNAME"
    rrdatas = ["home.${var.domain}."]
    ttl = "3600"
}

// add dependency on resource
data "template_file" "zones" {
    count = "${length(var.legacy_domains)}"
    template = "${google_dns_managed_zone.legacy.*.name[count.index]}"
}

output "name_to_zone" {
    value = "${zipmap(data.template_file.names.*.rendered,
               data.template_file.zones.*.rendered)}"
    sensitive = true
}
