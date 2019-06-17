data "terraform_remote_state" "phase_2" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_2"
}

data "terraform_remote_state" "phase_3" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_3"
}

data "terraform_remote_state" "phase_4" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_4"
}

locals {
    d = "."
    h = "-"
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"
    fqdn = "${data.terraform_remote_state.phase_2.fqdn}"
    glue_zone = "${data.terraform_remote_state.phase_2.glue_zone}"
    canonical_legacy_domains = "${data.terraform_remote_state.phase_2.canonical_legacy_domains}"
    managed_by = "Managed by terraform environment ${var.UUID} for project"
    cloud_gateway_external_ip = "${data.terraform_remote_state.phase_4.cloud_gateway_external_ip}"
    site_gateway_external_ip = "${data.terraform_remote_state.phase_4.site_gateway_external_ip}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
resource "google_dns_managed_zone" "domain" {
    name = "${replace(local.fqdn, local.d, local.h)}"
    dns_name = "${local.fqdn}."
    visibility = "public"
    description = "${local.managed_by} ${local.self["PROJECT"]}"
}

resource "google_dns_record_set" "domain_mx" {
    managed_zone = "${google_dns_managed_zone.domain.name}"
    name = "${google_dns_managed_zone.domain.dns_name}"
    type = "MX"
    rrdatas = ["10 mail.${google_dns_managed_zone.domain.dns_name}"]
    ttl = "${60 * 60 * 4}"
}

// ref: https://www.terraform.io/docs/providers/google/r/dns_record_set.html
resource "google_dns_record_set" "domain_glue" {
    count = "${local.glue_zone == "" ? 0 : 1}"
    managed_zone = "${replace(local.glue_zone, local.d, local.h)}"
    name = "${google_dns_managed_zone.domain.dns_name}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.domain.name_servers}"]
    ttl = "300"
}

locals {
    // The rest of the universe prefers domains without trailing dots
    domain_fqdn = "${substr(google_dns_managed_zone.domain.dns_name,
                            0, length(google_dns_managed_zone.domain.dns_name) - 1)}"
    site_validations = [
        "google-site-verification=f3NrFaSVqIGgQ8lS8XDZW_XN5gLjDOnnjqhP1awvic0",
        "google-site-verification=6DvLxVgmaBOEezUgrrntK7ZxGw3GlfUaAUGNvvSYl18",
        "google-site-verification=LylpAG6l9UsDtVrnqRo8SOlO1gk2lvr2MpXsxP261Do",
        "google-site-verification=kQ7bVgY98H0qXVEb0X9Tyfni2cU-ygKoHVEvD1c7-pA",
        "google-site-verification=3Prazw9vQPTC7Mwc-RzQFe7rxU2qZe8zwrXgyOCoGCE"
    ]
}

output "domain_fqdn" {
    value = "${local.domain_fqdn}"
    sensitive = true
}

output "domain_zone" {
    value = "${google_dns_managed_zone.domain.name}"
    sensitive = true
}

// Google gets ornery if it thinks we don't own the domains
resource "google_dns_record_set" "google-site-validation" {
    managed_zone = "${google_dns_managed_zone.domain.name}"
    name = "${google_dns_managed_zone.domain.dns_name}"
    type = "TXT"
    rrdatas = ["${local.site_validations}"]
    ttl = "${60 * 60 * 24 * 7}"
}

resource "google_dns_managed_zone" "legacy" {
    depends_on = ["google_dns_managed_zone.domain"]
    count = "${length(local.canonical_legacy_domains)}"
    name = "${replace(local.canonical_legacy_domains[count.index], local.d, local.h)}"
    dns_name = "${local.canonical_legacy_domains[count.index]}."
    visibility = "public"
    description = "${local.managed_by} ${local.self["PROJECT"]}"
}

resource "google_dns_record_set" "legacy_glue" {
    depends_on = ["google_dns_managed_zone.domain"]
    count = "${local.glue_zone == "" ? 0 : length(google_dns_managed_zone.legacy.*.name)}"
    managed_zone = "${google_dns_managed_zone.domain.name}"
    name = "${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "NS"
    rrdatas = ["${google_dns_managed_zone.legacy.*.name_servers[count.index]}"]
    ttl = "${60 * 60 * 4}"
}

resource "google_dns_record_set" "legacy_mx" {
    depends_on = ["google_dns_managed_zone.domain"]
    count = "${length(google_dns_managed_zone.legacy.*.name)}"
    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "MX"
    rrdatas = ["10 mail.${google_dns_managed_zone.domain.dns_name}"]
    ttl = "${60 * 60 * 4}"
}

resource "google_dns_record_set" "legacy-google-site-validation" {
    count = "${length(google_dns_managed_zone.legacy.*.name)}"
    managed_zone = "${google_dns_managed_zone.legacy.*.name[count.index]}"
    name = "${google_dns_managed_zone.legacy.*.dns_name[count.index]}"
    type = "TXT"
    rrdatas = ["${local.site_validations}"]
    ttl = "${60 * 60 * 24 * 7}"
}

data "template_file" "legacy_fqdns" {
    count = "${length(local.canonical_legacy_domains)}"
    template = "${substr(google_dns_managed_zone.legacy.*.dns_name[count.index],
                         0,
                         length(google_dns_managed_zone.legacy.*.dns_name[count.index]) - 1)}"
}

output "legacy_fqdns" {
    value = ["${data.template_file.legacy_fqdns.*.rendered}"]
    sensitive = true
}

locals {
    site_fqdn = "site.${google_dns_managed_zone.domain.dns_name}"
    site_zone = "${replace(substr(local.site_fqdn,
                                  0,
                                  length(local.site_fqdn) - 1),
                           local.d, local.h)}"
    cloud_fqdn = "cloud.${google_dns_managed_zone.domain.dns_name}"
    cloud_zone = "${replace(substr(local.cloud_fqdn,
                                   0,
                                   length(local.cloud_fqdn) - 1),
                            local.d, local.h)}"
}

module "site_subdomain" {
    source = "./modules/subdomain"
    providers {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    subdomain_fqdn = "${local.site_fqdn}"
    glue_zone = "${google_dns_managed_zone.domain.name}"
    mx_fqdn = "mail.${google_dns_managed_zone.domain.dns_name}"
    description = "${local.managed_by} ${local.self["PROJECT"]}"
}

module "cloud_subdomain" {
    source = "./modules/subdomain"
    providers {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    subdomain_fqdn = "${local.cloud_fqdn}"
    glue_zone = "${google_dns_managed_zone.domain.name}"
    description = "${local.managed_by} ${local.self["PROJECT"]}"
    mx_fqdn = "mail.${google_dns_managed_zone.domain.dns_name}"
}

locals {
    tsp = ["test", "stage", "prod"]

    // Google cloud DNS only permits trees deeper than 6 levels
    cloud_base = "${local.is_prod == 1
                    ? local.cloud_fqdn
                    : google_dns_managed_zone.domain.dns_name}"
    cloud_glue = "${local.is_prod == 1
                    ? module.cloud_subdomain.zone
                    : google_dns_managed_zone.domain.name}"

    _tsp_fqdns = ["test.${local.cloud_base}",
                  "stage.${local.cloud_base}",
                  "prod.${local.cloud_base}"]
    tsp_fqdns = "${zipmap(local.tsp, local._tsp_fqdns)}"

    _tsp_proj = ["${var.TEST_SECRETS["PROJECT"]}",
                 "${var.STAGE_SECRETS["PROJECT"]}",
                 "${var.PROD_SECRETS["PROJECT"]}"]
    tsp_proj = "${zipmap(local.tsp, local._tsp_proj)}"
}

module "test_cloud_subdomain" {
    source = "./modules/subdomain"
    providers {
        google.domain = "google.prod"
        google.subdomain = "google.test"
    }
    subdomain_fqdn = "${local.tsp_fqdns["test"]}"
    glue_zone = "${local.cloud_glue}"
    description = "${local.managed_by} ${local.tsp_proj["test"]}"
    mx_fqdn = "mail.${module.cloud_subdomain.fqdn}"
}

module "stage_cloud_subdomain" {
    source = "./modules/subdomain"
    providers {
        google.domain = "google.prod"
        google.subdomain = "google.stage"
    }
    subdomain_fqdn = "${local.tsp_fqdns["stage"]}"
    glue_zone = "${local.cloud_glue}"
    description = "${local.managed_by} ${local.tsp_proj["stage"]}"
    mx_fqdn = "mail.${module.cloud_subdomain.fqdn}"
}

module "prod_cloud_subdomain" {
    source = "./modules/subdomain"
    providers {
        google.domain = "google.prod"
        google.subdomain = "google.prod"
    }
    subdomain_fqdn = "${local.tsp_fqdns["prod"]}"
    glue_zone = "${local.cloud_glue}"
    description = "${local.managed_by} ${local.tsp_proj["prod"]}"
    mx_fqdn = "mail.${module.cloud_subdomain.fqdn}"
}

output "shortsub_fqdns" {
    value = {
        site = "${module.site_subdomain.common_fqdn}"
        cloud = "${module.site_subdomain.common_fqdn}"
        test = "${module.test_cloud_subdomain.common_fqdn}"
        stage = "${module.stage_cloud_subdomain.common_fqdn}"
        prod = "${module.prod_cloud_subdomain.common_fqdn}"
    }
    sensitive = true
}

locals {
    _tsp_zones = ["${module.test_cloud_subdomain.zone}",
                  "${module.stage_cloud_subdomain.zone}",
                  "${module.prod_cloud_subdomain.zone}"]
    tsp_zones = "${zipmap(local.tsp, local._tsp_zones)}"
}

resource "google_dns_record_set" "cloud_gateway" {
    depends_on = ["module.test_cloud_subdomain",
                  "module.stage_cloud_subdomain",
                  "module.prod_cloud_subdomain"]
    managed_zone = "${lookup(local.tsp_zones, var.ENV_NAME)}"
    name = "${lookup(local.tsp_fqdns, var.ENV_NAME)}"
    type = "A"
    rrdatas = ["${local.cloud_gateway_external_ip}"]
    ttl = "${60 * 60}"
}

resource "google_dns_record_set" "site_gateway" {
    managed_zone = "${module.site_subdomain.zone}"
    name = "${module.site_subdomain.fqdn}"
    type = "A"
    rrdatas = ["${local.is_prod == 1
                  ? local.site_gateway_external_ip
                  : local.cloud_gateway_external_ip}"]
    ttl = "${60 * 60}"
}

locals {
    // For production-use, duplicate to allow flipping one or more as needed,
    // otherwise always point at cloud gateway.
    services = {
        mail = "${local.is_prod == 1
                  ? google_dns_record_set.site_gateway.name
                  : google_dns_record_set.cloud_gateway.name}"
        smtp = "${local.is_prod == 1
                  ? google_dns_record_set.site_gateway.name
                  : google_dns_record_set.cloud_gateway.name}"
        imap = "${local.is_prod == 1
                  ? google_dns_record_set.site_gateway.name
                  : google_dns_record_set.cloud_gateway.name}"
        file = "${local.is_prod == 1
                  ? google_dns_record_set.site_gateway.name
                  : google_dns_record_set.cloud_gateway.name}"
        www  = "${local.is_prod == 1
                  ? google_dns_record_set.site_gateway.name
                  : google_dns_record_set.cloud_gateway.name}"
    }
    service_names = ["${keys(local.services)}"]
    service_fqdns = ["${values(local.services)}"]
}

resource "google_dns_record_set" "services" {
    count = "${length(local.service_names)}"
    managed_zone = "${google_dns_managed_zone.domain.name}"
    name = "${local.service_names[count.index]}.${google_dns_managed_zone.domain.dns_name}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

data "template_file" "service_fqdns" {
    count = "${length(local.service_names)}"
    template = "${substr(element(google_dns_record_set.services.*.rrdatas[count.index], 0),
                         0,
                         length(element(google_dns_record_set.services.*.rrdatas[count.index], 0)) - 1)}"
}

output "services_fqdns" {
    value = "${zipmap(local.service_names, data.template_file.service_fqdns.*.rendered)}"
    sensitive = true
}

resource "google_dns_record_set" "site_services" {
    count = "${length(local.service_names)}"
    managed_zone = "${module.site_subdomain.zone}"
    name = "${local.service_names[count.index]}.${module.site_subdomain.fqdn}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "cloud_services" {
    count = "${length(local.service_names)}"
    managed_zone = "${module.cloud_subdomain.zone}"
    name = "${local.service_names[count.index]}.${module.cloud_subdomain.fqdn}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "test_cloud_services" {
    count = "${length(local.service_names)}"
    provider = "google.test"
    managed_zone = "${module.test_cloud_subdomain.zone}"
    name = "${local.service_names[count.index]}.${module.test_cloud_subdomain.fqdn}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "stage_cloud_services" {
    count = "${length(local.service_names)}"
    provider = "google.stage"
    managed_zone = "${module.stage_cloud_subdomain.zone}"
    name = "${local.service_names[count.index]}.${module.stage_cloud_subdomain.fqdn}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}

resource "google_dns_record_set" "prod_cloud_services" {
    count = "${length(local.service_names)}"
    provider = "google.prod"
    managed_zone = "${module.prod_cloud_subdomain.zone}"
    name = "${local.service_names[count.index]}.${module.prod_cloud_subdomain.fqdn}"
    type = "CNAME"
    rrdatas = ["${local.service_fqdns[count.index]}"]
    ttl = "${60 * 60 * 24}"
}
