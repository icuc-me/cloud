
variable "private_network" {
    description = "Complete URI to the private network"
}

variable "testing" {
    description = "Dummy test sub-domain name guaranteed never to clash"
}

variable "public_fqdn" {
    description = "DNS suffix to append when forming zone names, e.g. 'example.com'"
}

variable "cloud_subdomain" {
    description = "subdomain of public_fqdn for google cloud resources"
}

variable "site_subdomain" {
    description = "subdomain of public_fqdn for non-cloud resources"
}

locals {
    e = ""
    d = "."
    h = "-"
    c = ","
    dom = "${var.testing == ""
             ? var.public_fqdn
             : join("-", list(var.testing, var.public_fqdn))}"
    # order is significant to subsequent, nested resources
    subnames = ["",
                "${var.site_subdomain}.",
                "${var.cloud_subdomain}.",
                "test.${var.cloud_subdomain}.",
                "stage.${var.cloud_subdomain}.",
                "prod.${var.cloud_subdomain}."]
    n_subs = "${length(local.subnames)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "domains" {
  count = "${local.n_subs}"
  name = "${replace(local.subnames[count.index], local.d, local.h)}${replace(local.dom, local.d, local.h)}"
  dns_name = "${local.subnames[count.index]}${local.dom}."
  visibility = "public"  # N/B: only actual when registrar points at assigned NS
}

output "zone_names" {
    value = "${zipmap(concat(list("."), slice(local.subnames, 1, local.n_subs)),
                      google_dns_managed_zone.domains.*.name)}"
    sensitive = true
}

// Strip off trailing "." in dns_name
data "template_file" "common_name" {
    count = "${local.n_subs}"
    template = "${substr(google_dns_managed_zone.domains.*.dns_name[count.index],
                         0,
                         length(google_dns_managed_zone.domains.*.dns_name[count.index]) - 1)}"
}

output "dns_names" {
    value = "${zipmap(concat(list("."), slice(local.subnames, 1, local.n_subs)),
                      data.template_file.common_name.*.rendered)}"
    sensitive = true
}

data "template_file" "common_dns" {
    count = "4"
    template = "${substr(element(google_dns_managed_zone.domains.*.name_servers[0], count.index),
                         0,
                         length(element(google_dns_managed_zone.domains.*.name_servers[0], count.index)) - 1)}"
}

output "nameservers" {
    value = ["${data.template_file.common_dns.*.rendered}"]
    sensitive = true
}

locals {
    # order must be same as local.subnames
    fqdn_glue = ["${google_dns_managed_zone.domains.*.dns_name[1]}",
                 "${google_dns_managed_zone.domains.*.dns_name[2]}"]
    fqdn_glue_ns = ["${join(local.c, google_dns_managed_zone.domains.*.name_servers[1])}",
                    "${join(local.c, google_dns_managed_zone.domains.*.name_servers[2])}"]
    n_fqdn_glue = "${length(local.fqdn_glue)}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "fqdn_glue" {
    count = "${local.n_fqdn_glue}"
    managed_zone = "${google_dns_managed_zone.domains.*.name[0]}"
    name = "${local.fqdn_glue[count.index]}"
    type = "NS"
    rrdatas = ["${split(local.c, element(local.fqdn_glue_ns, count.index))}"]
    ttl = 86400
}

locals {
    cloud_managed_zone = "${google_dns_managed_zone.domains.*.name[2]}"
    # order must be same as local.subnames
    cloud_glue = ["${google_dns_managed_zone.domains.*.dns_name[3]}",
                  "${google_dns_managed_zone.domains.*.dns_name[4]}",
                  "${google_dns_managed_zone.domains.*.dns_name[5]}"]
    cloud_glue_ns = ["${join(local.c, google_dns_managed_zone.domains.*.name_servers[3])}",
                     "${join(local.c, google_dns_managed_zone.domains.*.name_servers[4])}",
                     "${join(local.c, google_dns_managed_zone.domains.*.name_servers[5])}"]
    n_cloud_glue = "${length(local.cloud_glue)}"
}

resource "google_dns_record_set" "cloud_glue" {
    count = "${local.n_cloud_glue}"
    managed_zone = "${local.cloud_managed_zone}"
    name = "${local.cloud_glue[count.index]}"
    type = "NS"
    rrdatas = ["${split(local.c, element(local.cloud_glue_ns, count.index))}"]
    ttl = 86400
}

module "myip" {
    source = "./myip"
}

locals {
    site_managed_zone = "${google_dns_managed_zone.domains.*.name[1]}"
}

resource "google_dns_record_set" "site_gateway" {
    managed_zone = "${local.site_managed_zone}"
    name = "gateway.${google_dns_managed_zone.domains.*.dns_name[1]}"
    type = "A"
    rrdatas = ["${module.myip.ip}"]
    ttl = 600
}

output "site_gateway" {
    value = "${map(google_dns_record_set.site_gateway.name, module.myip.ip)}"
    sensitive = true
}
