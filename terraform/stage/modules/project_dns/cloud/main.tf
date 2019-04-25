
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

module "cloud" {
    source = "../sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.prod"
    }
    domain = "${var.domain}"
    base_zone = "${var.zone}"
    subdomain = "${var.cloud}"
}

locals {
    cloud_zone = "${module.cloud.name_to_zone[var.cloud]}"
}

module "test" {
    source = "../sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.test"
    }
    domain = "${var.cloud}.${var.domain}"
    base_zone = "${local.cloud_zone}"
    subdomain = "test"
}

module "stage" {
    source = "../sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.stage"
    }
    domain = "${var.cloud}.${var.domain}"
    base_zone = "${local.cloud_zone}"
    subdomain = "stage"
}

module "prod" {
    source = "../sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.prod"
    }
    domain = "${var.cloud}.${var.domain}"
    base_zone = "${local.cloud_zone}"
    subdomain = "prod"
}

resource "google_dns_record_set" "gateway" {
    managed_zone = "${module.prod.name_to_zone["prod"]}"
    name = "gateway.prod.${var.cloud}.${var.domain}."
    type = "A"
    rrdatas = ["${var.gateway}"]
    ttl = 600
}

output "name_to_zone" {
    value = "${merge(map("cloud", local.cloud_zone),
                     module.test.name_to_zone,
                     module.stage.name_to_zone,
                     module.prod.name_to_zone)}"
    sensitive = true
}

output "gateway" {
    // strip off trailing '.'
    value = "${substr(google_dns_record_set.gateway.name, 0,
                      length(google_dns_record_set.gateway.name) - 1)}"
    sensitive = true
}
