
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

variable "domain_fqdn" {
    description = "Base DNS name to create and manage.  For test and stage env. this is assumed to be their respective, complete subdomain, including the additional env_uuid prefix"
}

variable "glue_zone" {
    description = "When non-empty, add glue record to this zone, referring to domain_fqdn nameservers.  Also modifies the layout slightly for entries under the cloud subdomain."
}

variable "legacy_domains" {
    description = "List of complete legacy FQDNs to manage."
    type = "list"
}

variable "env_uuid" {
    description = "UUID of the current environment for zone descriptions"
}

/*****/

data "google_client_config" "domain" { provider = "google.prod" }

locals {
    d = "."
    h = "-"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "domain" {
    provider = "google.prod"
    name = "${replace(var.domain_fqdn, local.d, local.h)}"
    dns_name = "${var.domain_fqdn}."
    visibility = "public"
    description = "Managed for terraform environment ${var.env_uuid} by project ${data.google_client_config.domain.project}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "domain_glue" {
    count = "${var.glue_zone == "" ? 0 : 1}"
    provider = "google.prod"
    managed_zone = "${replace(var.glue_zone, local.d, local.h)}"
    name = "${google_dns_managed_zone.domain.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.domain.name_servers}"]
    ttl = "${60 * 60 * 24}"
}

locals {
    // Other tooling dislikes the final trailing "."
    domain = "${substr(google_dns_managed_zone.domain.dns_name,
                       0,
                       length(google_dns_managed_zone.domain.dns_name) - 1)}"
}

/*****/

module "cloud_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    glue_zone = "${google_dns_managed_zone.domain.name}"
    subdomain_fqdn = "cloud.${local.domain}"
    env_uuid = "${var.env_uuid}"
}

locals {
    cloud_zone = "${element(values(module.cloud_subdomain.name_to_zone), 0)}"
    cloud_fqdn = "${element(keys(module.cloud_subdomain.name_to_zone), 0)}.${local.domain}"
    cloud_fqdn_elements = ["${split(local.d, local.cloud_fqdn)}"]
    // Workaround: Google does not support deeper than 6 levels of domains
    short_cloud_fqdn = "${join(local.d,
                               slice(local.cloud_fqdn_elements, 1, length(local.cloud_fqdn_elements)))}"
    short_cloud_zone = "${replace(local.short_cloud_fqdn, local.d, local.h)}"
}


module "test_cloud_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.test"
    }
    glue_zone = "${var.glue_zone == ""
                   ? local.cloud_zone
                   : local.short_cloud_zone}"
    subdomain_fqdn = "test.${var.glue_zone == ""
                             ? local.cloud_fqdn
                             : local.short_cloud_fqdn}"
    env_uuid = "${var.env_uuid}"
}

module "stage_cloud_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.stage"
    }
    glue_zone = "${var.glue_zone == ""
                   ? local.cloud_zone
                   : local.short_cloud_zone}"
    subdomain_fqdn = "stage.${var.glue_zone == ""
                             ? local.cloud_fqdn
                             : local.short_cloud_fqdn}"
    env_uuid = "${var.env_uuid}"
}

/*****/

module "site_subdomain" {
    source = "./subdomain"
    providers = {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    glue_zone = "${google_dns_managed_zone.domain.name}"
    subdomain_fqdn = "site.${local.domain}"
    env_uuid = "${var.env_uuid}"
}

/*****/

module "legacy" {
    source = "./legacy"
    providers = { google = "google.prod" }
    legacy_domains = ["${var.legacy_domains}"]
    domain_zone = "${google_dns_managed_zone.domain.name}"
    glue_count = "${var.glue_zone == ""
                    ? 0
                    : length(var.legacy_domains)}"
    env_uuid = "${var.env_uuid}"
}

output "name_to_zone" {
    value = "${merge(map("domain", google_dns_managed_zone.domain.name),
                     module.cloud_subdomain.name_to_zone,
                     module.test_cloud_subdomain.name_to_zone,
                     module.stage_cloud_subdomain.name_to_zone,
                     module.site_subdomain.name_to_zone,
                     module.legacy.name_to_zone)}"
    sensitive = true
}

output "name_to_ns" {
    value = "${merge(map("domain", google_dns_managed_zone.domain.name_servers),
                     module.cloud_subdomain.name_to_ns,
                     module.test_cloud_subdomain.name_to_ns,
                     module.stage_cloud_subdomain.name_to_ns,
                     module.site_subdomain.name_to_ns,
                     module.legacy.name_to_ns)}"
    sensitive = true
}

output "name_to_fqdn" {
    value = "${merge(map("domain", local.domain),
                     module.cloud_subdomain.name_to_fqdn,
                     module.test_cloud_subdomain.name_to_fqdn,
                     module.stage_cloud_subdomain.name_to_fqdn,
                     module.site_subdomain.name_to_fqdn,
                     module.legacy.name_to_fqdn)}"
    sensitive = true
}

output "legacy_shortnames" {
    value = ["${keys(module.legacy.name_to_zone)}"]
    sensitive = true
}
