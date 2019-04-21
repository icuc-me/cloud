
variable "private_network" {
    description = "Complete URI to the private network"
}

variable "testing" {
    description = "Dummy test sub-domain name guaranteed never to clash"
}

variable "public_fqdn" {
    description = "DNS suffix to append when forming zone names, e.g. 'example.com'"
}

locals {
    e = ""
    d = "."
    h = "-"
    dom = "${var.testing == ""
             ? var.public_fqdn
             : join(".", list(var.testing, var.public_fqdn))}"
    subhnames = ["", "test-", "stage-", "prod-"]
    subdnames = ["", "test.", "stage.", "prod."]
    n_subs = "${var.testing == "" ? 4 : 2}"
}

resource "google_dns_managed_zone" "domains" {
  count = "${local.n_subs}"
  name = "${local.subhnames[count.index]}${replace(local.dom, local.d, local.h)}"
  dns_name = "${local.subdnames[count.index]}${local.dom}."
  visibility = "public"  # N/B: only actual when registrar points at assigned NS
}

output "dom_ns" {
    value = "${zipmap(slice(local.subdnames, 0, local.n_subs),
                      google_dns_managed_zone.domains.*.name_servers)}"
    sensitive = true
}
