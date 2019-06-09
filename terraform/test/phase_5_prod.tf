/****
****  ACME Simply not reliable enough
***** TODO: https://github.com/terraform-providers/terraform-provider-acme/issues/65
****/

// ref: https://www.terraform.io/docs/providers/acme/r/registration.html
resource "tls_private_key" "reg_private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "acme_registration" "reg" {
    account_key_pem = "${tls_private_key.reg_private_key.private_key_pem}"
    email_address   = "${local.strongbox_contents["acme_reg_ename"]}"
}

resource "tls_private_key" "cert_private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

locals {
    e = ""
    wildfmt = "*.%s"
    wild_legacy_sans = ["${formatlist(local.wildfmt, local.canonical_legacy_domains)}"]

    // Only required in prod w/o 6-level deep limitation
    wild_domain = "*.${local.domain_fqdn}"
    wild_domain_san = "${local.is_prod == 1
                         ? local.wild_domain
                         : local.e}"

    site_cloud_sans = ["${substr(module.site_subdomain.fqdn, 0, length(module.site_subdomain.fqdn) - 1)}",
                       "${substr(module.cloud_subdomain.fqdn, 0, length(module.cloud_subdomain.fqdn) - 1)}",
                       "${substr(module.test_cloud_subdomain.fqdn, 0, length(module.test_cloud_subdomain.fqdn) - 1)}",
                       "${substr(module.stage_cloud_subdomain.fqdn, 0, length(module.stage_cloud_subdomain.fqdn) - 1)}",
                       "${substr(module.prod_cloud_subdomain.fqdn, 0, length(module.prod_cloud_subdomain.fqdn) - 1)}"]
    wild_site_cloud = ["${formatlist(local.wildfmt, local.site_cloud_sans)}"]
    sans = ["${compact(concat(local.canonical_legacy_domains,
                              local.wild_legacy_sans,
                              local.wild_site_cloud,
                              list(local.wild_domain_san)))}"]
}

resource "acme_certificate" "domain" {
    // not all resources are direct references for ease of fqdn trailing-dot removal
    depends_on = ["google_dns_managed_zone.domain",
                  "module.site_subdomain", "module.cloud_subdomain",
                  "module.test_cloud_subdomain", "module.stage_cloud_subdomain",
                  "module.prod_cloud_subdomain", "google_dns_managed_zone.legacy"]
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    // Must subtract trailing period
    common_name = "${local.domain_fqdn}"
    subject_alternative_names = ["${local.sans}"]
    key_type = "${tls_private_key.cert_private_key.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 20 : 3}"
    certificate_p12_password = "${local.strongkeys[var.ENV_NAME]}"
    // decouple from default nameservers on runtime host
    recursive_nameservers = ["8.8.8.8", "8.8.4.4"]
    dns_challenge {
        provider = "gcloud"
        config {
            /* TODO: Default timings?
            GCE_POLLING_INTERVAL = "30"
            GCE_PROPAGATION_TIMEOUT = "600"
            GCE_TTL = "60"
            */
            GCE_PROJECT = "${local.self["PROJECT"]}"
            GCE_SERVICE_ACCOUNT_FILE = "${local.self["CREDENTIALS"]}"
        }
    }
}

resource "local_file" "public_key" {
    sensitive_content = "${tls_private_key.cert_private_key.public_key_pem}"
    filename = "${path.root}/output_files/letsencrypt.key.pub"
}

resource "local_file" "private_key" {
    sensitive_content = "${tls_private_key.cert_private_key.private_key_pem}"
    filename = "${path.root}/output_files/letsencrypt.key"
}

resource "local_file" "cert" {
    sensitive_content = "${acme_certificate.domain.certificate_pem}"
    filename = "${path.root}/output_files/letsencrypt.cert.pem"
}
