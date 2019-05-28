data "terraform_remote_state" "phase_1" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_1"
}

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

locals {
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"
    // In test & stage, this will be mock-uri's
    strongbox_uris = "${data.terraform_remote_state.phase_1.strongbox_uris}"
}

// Set access controls on buckets and objects.  Mock buckets used in test & stage
module "strongbox_acls" {
    source = "./modules/strongbox_acls"
    providers { google = "google" }
    set_acls = "1"
    strongbox_uris = "${local.strongbox_uris}"
    env_readers = "${local.strongbox_contents["env_readers"]}"
}

output "strongbox_acls" {
    value = {
        object_readers = "${module.strongbox_acls.object_readers}"
        bucket_readers = "${module.strongbox_acls.bucket_readers}"
    }
    sensitive = true
}

locals {
    e = ""
    c = ","
    d = "."
    h = "-"
    // FQDN for stage and test assumed to contain their subdomain names,
    // but need to add UUID to prevent clashes.
    // see modules/project_dns/notes.txt
    fqdn = "${local.is_prod== 1
              ? local.strongbox_contents["fqdn"]
              : join(local.d, list(var.UUID, local.strongbox_contents["fqdn"]))}"
    fqdn_names = ["${split(local.d, local.fqdn)}"]
    fqdn_parent = "${join(local.d, slice(local.fqdn_names, 1, length(local.fqdn_names)))}"
    // Needed to attach e.g test_123abc.test.example.com into test.example.com (or similar for stage)
    glue_zone = "${local.is_prod == 1
                   ? local.e
                   : replace(local.fqdn_parent, local.d, local.h)}"
    // assumed to be shortnames unless prod-environment
    legacy_domains = ["${split(local.c, local.strongbox_contents["legacy_domains"])}"]
    // Conditionals cannot return lists, only strings, use fomatlist() as workaround
    t = "%s"
    legacy_domain_fmt = "${local.is_prod == 1
                           ? local.t
                           : join(local.d, list(local.t, local.fqdn))}"
    canonical_legacy_domains = ["${formatlist(local.legacy_domain_fmt, local.legacy_domains)}"]
}

// see also: phase_3_test.tf and phase_3_stage.tf
module "project_dns" {
    source = "./modules/project_dns"
    providers {  // N/B: In test & stage, these are NOT the actual named providers!
        google.test = "google.test"
        google.stage = "google.stage"
        google.prod = "google.prod"
    }
    domain_fqdn = "${local.fqdn}"
    glue_zone = "${local.glue_zone}"  // empty-string in prod. env
    legacy_domains = ["${local.canonical_legacy_domains}"]
    env_uuid = "${var.UUID}"
}

output "name_to_zone" {
    value = "${module.project_dns.name_to_zone}"
    sensitive = true
}

output "name_to_fqdn" {
    value = "${module.project_dns.name_to_fqdn}"
    sensitive = true
}

output "canonical_legacy_domains" {
    value = "${local.canonical_legacy_domains}"
    sensitive = true
}

output "legacy_shortnames" {
    value = ["${module.project_dns.legacy_shortnames}"]
    sensitive = true
}

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

resource "acme_certificate" "fqdn_certificate" {
    depends_on = ["module.project_dns"]  // not all resources are direct
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    common_name = "${module.project_dns.name_to_fqdn["domain"]}"
    subject_alternative_names = ["${local.sans}"]
    key_type = "${tls_private_key.cert_private_key.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 20 : 0}"
    certificate_p12_password = "${local.strongkeys[var.ENV_NAME]}"
    // decouple from default nameservers on runtime host
    recursive_nameservers = ["8.8.8.8:53", "8.8.4.4:53"]  // docs say they need ports

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

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
