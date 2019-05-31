/*

Update the DNS tree based on the following scheme:

0. A top-level zone stores canonical CNAME records for a list of services, pointing at the
   actual server DNS names (e.g. gateway.site.example.com)
1. All zones beneith top-level zone contain records for same list of services, but pointing at
   the top-level DNS names (e.g. foo.stage.cloud.example.com -> foo.example.com).
3. All zones contain a MX record pointing at their local 'mail' CNAME record.
4. Appropriate zones contain an A record for 'gateway' with an IP address.

*/

variable "domain_zone" {
    description = "Top-level zone name for canonical CNAME records"
}

variable "gateways" {
    description = "Mapping of zone-name to IP address of managed 'gateway' A record."
    type = "map"
}

variable "gateway_count" {
    description = "Number of gateways present in gateways variable."
}

variable "service_destinations" {
    description = "Mapping of service names ('mail', 'www', etc.) to destination 'gateway' zone"
    type = "map"
}

// These must be static to allow dynamic service names
variable "managed_zones" {
    description = "List of up to 10 zone names to manage, service CNAMES will be added pointing back to domain_zone"
    type = "list"
    default = []
}

/*****/

data "google_dns_managed_zone" "gateway" {
    count = "${var.gateway_count}"
    name = "${element(keys(var.gateways), count.index)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "primary_a" {
    count = "${var.gateway_count}"
    managed_zone = "${element(keys(var.gateways), count.index)}"
    name = "gateway.${data.google_dns_managed_zone.gateway.*.dns_name[count.index]}"
    type = "A"
    rrdatas = ["${element(values(var.gateways), count.index)}"]
    ttl = "${60 * 60}"
}

/*****/

data "google_dns_managed_zone" "domain" {
    name = "${var.domain_zone}"
}

locals {
    services = ["${keys(var.service_destinations)}"]
    service_dest_zones = ["${values(var.service_destinations)}"]
}

data "google_dns_managed_zone" "service" {
    count = "${length(local.service_dest_zones)}"
    name = "${local.service_dest_zones[count.index]}"
}

resource "google_dns_record_set" "domain_mx" {
    managed_zone = "${var.domain_zone}"
    name = "${data.google_dns_managed_zone.domain.dns_name}"
    type = "MX"
    rrdatas = ["10 mail.${data.google_dns_managed_zone.domain.dns_name}"]
    ttl = "${60 * 60 * 4}"
}

resource "google_dns_record_set" "domain_services" {
    count = "${length(data.google_dns_managed_zone.service.*.name)}"
    managed_zone = "${var.domain_zone}"
    name = "${local.services[count.index]}.${data.google_dns_managed_zone.domain.dns_name}"
    type = "CNAME"
    rrdatas = ["gateway.${data.google_dns_managed_zone.service.*.dns_name[count.index]}"]
    ttl = "${60 * 60 * 2}"
}

/*****/

locals {
    managed_count = "${length(var.managed_zones)}"
    managed_zones = ["${data.template_file.managed_zones.*.rendered}"]
}

data "template_file" "managed_zones" {
    count = "10"
    template = "${count.index < local.managed_count
                  ? element(var.managed_zones, count.index)
                  : ""}"
}

// Impossible to loop with modules
module "managed_zone1" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 0)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone2" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 1)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone3" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 2)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone4" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 3)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone5" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 4)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone6" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 5)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone7" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 6)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone8" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 7)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone9" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 8)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}

module "managed_zone10" {
    source = "./managed_zone"
    managed_zone = "${element(local.managed_zones, 9)}"
    domain_fqdn = "${data.google_dns_managed_zone.domain.dns_name}"
    services = ["${local.services}"]
}
