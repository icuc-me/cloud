/****
****  Should be able to do acme in all env
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
    wildfmt = "*.%s"
    sans = ["${formatlist(local.wildfmt,
                          concat(list(lookup(module.project_dns.name_to_fqdn, "domain"),
                                      lookup(module.project_dns.name_to_fqdn, "site"),
                                      lookup(module.project_dns.name_to_fqdn, "cloud")),
                                 local.canonical_legacy_domains,
                                 ))}"]
}

data "google_dns_managed_zone" "domain" {
    // Don't create cert until domain is filled out
    depends_on = ["module.project_dns", "module.dns_records"]
    name = "${module.project_dns.name_to_zone["domain"]}"
}

resource "acme_certificate" "domain" {
    depends_on = ["module.project_dns"]  // not all resources are direct
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    // Must subtract trailing period
    common_name = "${substr(data.google_dns_managed_zone.domain.dns_name,
                            0,
                            length(data.google_dns_managed_zone.domain.dns_name) - 1)}"
    subject_alternative_names = ["${local.sans}"]
    key_type = "${tls_private_key.cert_private_key.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 20 : 3}"
    certificate_p12_password = "${local.strongkeys[var.ENV_NAME]}"
    // decouple from default nameservers on runtime host
    recursive_nameservers = ["8.8.8.8", "8.8.4.4"]
    dns_challenge {
        provider = "gcloud"
        config {
            // 5 & 180 (default) too quick & slow, root entry needs more time
            GCE_POLLING_INTERVAL = "10"
            GCE_PROPAGATION_TIMEOUT = "300"
            GCE_TTL = "60"
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
