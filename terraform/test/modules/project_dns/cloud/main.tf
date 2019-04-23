
provider "google" {}

variable "cloud_fqdn" {
    description = "FQDN of site"
}

variable "cloud_name" {
    description = "Name of managed site zone"
}

variable "gateway" {
    description = "IP address of cloud gateway"
}

resource "google_dns_record_set" "gateway" {
    managed_zone = "${var.cloud_name}"
    name = "gateway.${var.cloud_fqdn}."
    type = "A"
    rrdatas = ["${var.gateway}"]
    ttl = 600
}

output "fqdn_rrdata" {
    value = "${map(substr(google_dns_record_set.gateway.name
                          0, length(google_dns_record_set.gateway.name) - 1),
                   join(",", google_dns_record_set.gateway.rrdatas))}"
    sensitive = true
}
