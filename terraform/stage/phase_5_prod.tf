/****
****  ACME Simply not reliable enough
***** TODO: https://github.com/terraform-providers/terraform-provider-acme/issues/65
****/

// ref: https://www.terraform.io/docs/providers/acme/r/registration.html
resource "tls_private_key" "registration" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "acme_registration" "registration" {
    account_key_pem = "${tls_private_key.registration.private_key_pem}"
    email_address   = "${local.strongbox_contents["acme_reg_ename"]}"
}

locals {
    e = ""
    wildfmt = "*.%s"
    legacy_fqdns = ["${formatlist(local.wildfmt, local.canonical_legacy_domains)}"]

    // Only required in prod w/o 6-level deep limitation
    wild_domain = "*.${local.domain_fqdn}"
    wild_domain_san = "${local.is_prod == 1
                         ? local.wild_domain
                         : local.e}"
    // test, stage subdomain zones nested differently outside of prod env, no wild-SANs needed
    project_cloud_subdomains = [
        "${local.is_prod == 1 ? module.prod_cloud_subdomain.common_fqdn : ""}"
    ]
    site_cloud_fqdns = ["${module.site_subdomain.common_fqdn}",
                        "${module.cloud_subdomain.common_fqdn}"]
    wild_site_cloud = ["${formatlist(local.wildfmt,
                                     compact(concat(local.site_cloud_fqdns,
                                                    local.project_cloud_subdomains)))}"]
    sans = ["${compact(concat(local.canonical_legacy_domains,
                              local.legacy_fqdns,
                              local.wild_site_cloud,
                              list(local.wild_domain_san)))}"]
}

resource "acme_certificate" "domain" {
    depends_on = ["google_dns_managed_zone.domain",
                  "module.site_subdomain", "module.cloud_subdomain",
                  "module.test_cloud_subdomain", "module.stage_cloud_subdomain",
                  "module.prod_cloud_subdomain", "google_dns_managed_zone.legacy"]
    account_key_pem = "${acme_registration.registration.account_key_pem}"
    // Must subtract trailing period
    common_name = "${local.domain_fqdn}"
    subject_alternative_names = ["${local.sans}"]
    key_type = "${tls_private_key.registration.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 30 : 3}"
    // decouple from default nameservers on runtime host
    recursive_nameservers = ["8.8.8.8", "8.8.4.4"]
    dns_challenge {
        provider = "gcloud"
        config {
            GCE_POLLING_INTERVAL = "60"
            GCE_PROPAGATION_TIMEOUT = "600"
            GCE_TTL = "120"
            GCE_PROJECT = "${local.self["PROJECT"]}"
            GCE_SERVICE_ACCOUNT_FILE = "${local.self["CREDENTIALS"]}"
        }
    }
}

resource "local_file" "key" {
    sensitive_content = "${acme_certificate.domain.private_key_pem}"
    filename = "${path.root}/output_files/letsencrypt.key"
}

resource "local_file" "cert" {
    sensitive_content = "${acme_certificate.domain.certificate_pem}"
    filename = "${path.root}/output_files/letsencrypt.cert.pem"
}
