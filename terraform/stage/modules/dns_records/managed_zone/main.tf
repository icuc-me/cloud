
variable "managed_zone" {
    description = "Optional, zone name to manage CNAMES for services, pointing back to domain_zone"
    default = ""
}

variable "domain_fqdn" {
    description = "Top-level FQDN hosting a canonical CNAME for each service"
}

variable "services" {
    description = "List of services to add CNAMES for in managed_zone pointing to domain_zone"
    type = "list"
}

/*****/

data "google_dns_managed_zone" "managed_zone" {
    count = "${var.managed_zone != "" ? 1 : 0}"
    name = "${var.managed_zone}"
}

resource "google_dns_record_set" "managed_zone1_services" {
    count = "${var.managed_zone != ""
               ? length(var.services)
               : 0}"
    managed_zone = "${data.google_dns_managed_zone.managed_zone.name}"
    name = "${var.services[count.index]}.${data.google_dns_managed_zone.managed_zone.dns_name}"
    type = "CNAME"
    rrdatas = ["${var.services[count.index]}.${var.domain_fqdn}"]
    ttl = "${60 * 60 * 8}"
}

resource "google_dns_record_set" "managed_zone_mx" {
    count = "${var.managed_zone != "" ? 1 : 0}"
    managed_zone = "${data.google_dns_managed_zone.managed_zone.name}"
    name = "${data.google_dns_managed_zone.managed_zone.dns_name}"
    type = "MX"
    rrdatas = ["10 mail.${data.google_dns_managed_zone.managed_zone.dns_name}"]
    ttl = "${60 * 60 * 16}"
}
