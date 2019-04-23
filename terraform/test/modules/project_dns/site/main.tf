
provider "google" {}

variable "site_fqdn" {
    description = "FQDN of site"
}

variable "site_name" {
    description = "Name of managed site zone"
}

module "myip" {
        source = "./myip"
}

resource "google_dns_record_set" "gateway" {
    managed_zone = "${var.site_name}"
    name = "gateway.${var.site_fqdn}."
    type = "A"
    rrdatas = ["${module.myip.ip}"]
    ttl = 600
}


output "fqdn_rrdata" {
    value = "${map(substr(google_dns_record_set.gateway.name
                          0, length(google_dns_record_set.gateway.name) - 1),
                   join(",", google_dns_record_set.gateway.rrdatas))}"
    sensitive = true
}
