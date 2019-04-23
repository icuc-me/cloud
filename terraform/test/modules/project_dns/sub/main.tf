
provider "google" {
    alias = "base"   // provider owning the 'base_fqdn' (below)
}

variable "base_fqdn" {
    description = "Right-most base dns name containing the subdomain"
}

variable "base_name" {
    description = "Right-most managed zone name of base_fqdn"
}


provider "google" {
    alias = "subdomain"  // provider owning the 'subdomain' (below)
}

variable "subdomain" {
    description = "left-most dns name of the subdomain"
}


locals {
    d = "."
    h = "-"
    fqdn = "${var.subdomain}.${var.base_fqdn}"
    name = "${replace(local.fqdn, local.d, local.h)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "sub" {
    provider = "google.subdomain"
    name = "${local.name}"
    dns_name = "${local.fqdn}."
    visibility = "public"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "glue" {
    provider = "google.base"
    managed_zone = "${google_dns_managed_zone.sub.name}"
    name = "${google_dns_managed_zone.sub.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.sub.name_servers}"]
    ttl = 86400
}

output "fqdn_name" {
    // strip trailing '.' from dns name
    value = "${map(substr(google_dns_managed_zone.sub.dns_name,
                          0, length(google_dns_managed_zone.sub.dns_name) - 1),
                   google_dns_managed_zone.sub.name)}"
    sensitive = true
}
