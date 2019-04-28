
provider "google" {
    alias = "test"
}

provider "google" {
    alias = "stage"
}

provider "google" {
    alias = "prod"
}

variable "domain" {
    description = "FQDN of base domain name"
}

variable "zone" {
    description = "Managed zone name of base domain"
}

variable "cloud" {
    description = "Short name of cloud subdomain"
}

variable "gateway" {
    description = "IP address of cloud gateway"
}

variable "project" {
    description = "Name of project managing these resources"
}

variable "env_name" {
    description = "Name of the current environment (test, stage, prod)"
}

module "cloud" {
    source = "../sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.prod"
    }
    project = "${var.project}"
    domain = "${var.domain}"
    base_zone = "${var.zone}"
    subdomain = "${var.cloud}"
}

locals {
    cloud_zone = "${module.cloud.name_to_zone[var.cloud]}"
}

resource "google_dns_record_set" "gateway" {
    managed_zone = "${module.cloud.name_to_zone[var.cloud]}"
    name = "gateway.${var.cloud}.${var.domain}."
    type = "A"
    rrdatas = ["${var.gateway}"]
    ttl = 600
}

output "name_to_zone" {
    value = "${merge(map("cloud", local.cloud_zone))}"
    sensitive = true
}

output "gateway" {
    // strip off trailing '.'
    value = "${substr(google_dns_record_set.gateway.name, 0,
                      length(google_dns_record_set.gateway.name) - 1)}"
    sensitive = true
}
