
// N/B: In stage and test environments, all three providers will be the same!
provider "google" {
    alias = "test"
}

provider "google" {
    alias = "stage"
}

provider "google" {
   alias = "prod"
}

/*****/

variable "glue_fqdn" {
    description = "When non-empty, add glue record in zone cooresponding to this name, pointing at name-servers for domain_fqdn.  When empty, create managed subdomains for test and stage, in their respective projects using their prodiders."
}

variable "domain_fqdn" {
    description = "base DNS name to create, then append to all managed zone names"
}

variable "legacy_domains" {
    description = "List of legacy FQDNs to manage with CNAMES into var.domain_fqdn"
    type = "list"
}

variable "env_uuid" {
    description = "UUID of the current environment"
}

variable "env_name" {
    description = "Name of the current environment (test, stage, prod)"
}


/*****/

locals {
    d = "."
    h = "-"
    // Use conditional for clarity of intent
    glue_zone = "${var.glue_fqdn == ""
                   ? ""
                   : replace(var.glue_fqdn, local.d, local.h)}"
}

module "domain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"  // Actually test, in test env. and stage in stage env.
        google.subdomain = "google.prod"  // Actually test, in test env. and stage in stage env.
    }
    glue_zone = "${local.glue_zone}"  // may be empty-string
    subdomain_fqdn = "${var.domain_fqdn}"
    env_uuid = "${var.env_uuid}"
}

locals {
    fqdn_elements = ["${split(local.d, var.domain_fqdn)}"]
    // subdomain name_to_zone map uses shortnames
    fqdn = "${element(keys(module.domain.name_to_zone), 0)
             }.${join(local.d, slice(local.fqdn_elements, 1, length(local.fqdn_elements)))}"
    zone = "${element(values(module.domain.name_to_zone), 0)}"
}

output "fqdn" {
    value = "${local.fqdn}"
    sensitive = true
}

output "zone" {
    value = "${local.zone}"
    sensitive = true
}

data "google_dns_managed_zone" "domain" {
    depends_on = ["module.domain"]
    name = "${local.zone}"
}

output "ns" {
    value = ["${data.google_dns_managed_zone.domain.name_servers}"]
    sensitive = true
}

/*****/

module "cloud_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    glue_zone = "${local.zone}"
    subdomain_fqdn = "cloud.${local.fqdn}"
    env_uuid = "${var.env_uuid}"
}

locals {
    cloud_zone = "${element(values(module.cloud_subdomain.name_to_zone), 0)}"
    test_cloud_fqdn = "test.cloud.${local.fqdn}"
    stage_cloud_fqdn = "stage.cloud.${local.fqdn}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "test_cloud" {
    count = "${var.glue_fqdn == "" ? 1 : 0}"
    provider = "google.test"
    name = "${replace(local.test_cloud_fqdn, local.d, local.h)}"
    dns_name = "${local.test_cloud_fqdn}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid} for test project use"
}


// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "test_cloud_glue" {
    count = "${var.glue_fqdn == "" ? 1 : 0}"
    provider = "google.prod"
    managed_zone = "${local.cloud_zone}"
    name = "${google_dns_managed_zone.test_cloud.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.test_cloud.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_managed_zone" "stage_cloud" {
    count = "${var.glue_fqdn == "" ? 1 : 0}"
    provider = "google.stage"
    name = "${replace(local.stage_cloud_fqdn, local.d, local.h)}"
    dns_name = "${local.stage_cloud_fqdn}."
    visibility = "public"
    description = "Managed by terraform environment ${var.env_uuid} for stage project use"
}

resource "google_dns_record_set" "stage_cloud_glue" {
    count = "${var.glue_fqdn == "" ? 1 : 0}"
    provider = "google.prod"
    managed_zone = "${local.cloud_zone}"
    name = "${google_dns_managed_zone.stage_cloud.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.stage_cloud.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

/*****/

module "site_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    glue_zone = "${local.zone}"
    subdomain_fqdn = "site.${local.fqdn}"
    env_uuid = "${var.env_uuid}"
}

/*****/

module "legacy" {
    source = "./legacy"
    providers = { google = "google.prod" }
    legacy_domains = "${var.legacy_domains}"
    dest_domain = "${local.fqdn}"
    env_uuid = "${var.env_uuid}"
}

resource "google_dns_record_set" "legacy_glue" {
    count = "${var.glue_fqdn != "" ? length(var.legacy_domains) : 0}"
    provider = "google.test"
    managed_zone = "${local.zone}"
    name = "${var.legacy_domains[count.index]}."
    type = "NS"
    rrdatas = ["${module.legacy.name_to_nameservers[var.legacy_domains[count.index]]}"]
    ttl = "${60 * 60 * 24}"
}

output "name_to_zone" {
    value = "${merge(map(local.fqdn, local.zone),
                     module.cloud_subdomain.name_to_zone,
                     module.site_subdomain.name_to_zone,
                     module.legacy.name_to_zone)}"
    sensitive = true
}
