
provider "google" {
    alias = "test"
}

provider "google" {
    alias = "stage"
}

provider "google" {
    alias = "prod"
}

variable "base_fqdn" {
    description = "base DNS suffix to append to all managed zone names, e.g. 'example.com'"
}

variable "testing" {
    description = "test subdomain of base_fqdn to contain test items or blank for prod. use"
}

variable "cloud_subdomain" {
    description = "subdomain for google cloud resources"
}

variable "site_subdomain" {
    description = "subdomain of for non-cloud resources"
}

variable "gateway" {
    description = "IP address of cloud gateway"
}

locals {
    domain = "${var.testing == ""
                ? var.public_fqdn
                : join(".", list(var.testing, var.base_fqdn))}"
}

module "base" {
    source = "./base"
    providers = { google = "google.prod" }
    domain = "${local.domain}"
    cloud_subdomain = "${var.cloud_subdomain}"
    site_subdomain = "${var.site_subdomain}"
}

locals {
    cloud_fqdn = "${join(".", list(var.cloud_subdomain, local.domain))}"
    cloud_name = "${module.base.fqdn_name[local.cloud_fqdn]}"

    site_fqdn = "${join(".", list(var.site_subdomain, local.domain))}"
    site_name = "${module.base.fqdn_name[local.site_fqdn]}"
}

module "test" {
    source = "./sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.test"
    }
    base_fqdn = "${local.cloud_fqdn}"
    base_name = "${local.cloud_name}"
    subdomain = "test"
}

module "stage" {
    source = "./sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.stage"
    }
    base_fqdn = "${local.cloud_fqdn}"
    base_name = "${local.cloud_name}"
    subdomain = "stage"
}

module "prod" {
    source = "./sub"
    providers = {
        google.base = "google.prod"
        google.subdomain = "google.prod"
    }
    base_fqdn = "${local.cloud_fqdn}"
    base_name = "${local.cloud_name}"
    subdomain = "prod"
}

module "site" {
    source = "./site"
    providers = { google = "google.prod" }
    site_fqdn = "${local.site_fqdn}"
    site_name = "${local.site_name}"
}

output "fqdn" {
    value = 
}

output "dns_data" {
    value = "${merge(module.base.fqdn_names,
                     module.test.fqdn_name,
                     module.stage.fqdn_name,
                     module.prod.fqdn_name,
                     module.site.fqdn_rrdata,
                     map("fqdn_ns",
                         join(",", module.base.fqdn_ns)))}"
    sensitive = true
}
