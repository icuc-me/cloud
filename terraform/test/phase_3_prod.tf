locals {
    ci_svc_acts = "${data.terraform_remote_state.phase_2.ci_svc_acts}"
    ci_act_roles = [
        "roles/storage.admin", "roles/compute.admin", "roles/compute.networkAdmin",
        "roles/iam.serviceAccountUser", "roles/dns.admin"
    ]

    img_svc_acts = "${data.terraform_remote_state.phase_2.img_svc_acts}"
    img_act_roles = [
        "roles/compute.admin", "roles/iam.serviceAccountUser"
    ]
}

// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
resource "google_project_iam_member" "test_ci_svc_act_iam" {
    provider = "google.test"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["test"]}"
}

resource "google_project_iam_member" "test_img_svc_act_iam" {
    provider = "google.test"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["test"]}"
}

resource "google_project_iam_member" "stage_ci_svc_act_iam" {
    provider = "google.stage"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["stage"]}"
}

resource "google_project_iam_member" "stage_img_svc_act_iam" {
    provider = "google.stage"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["stage"]}"
}

resource "google_project_iam_member" "prod_ci_svc_act_iam" {
    provider = "google.prod"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["prod"]}"
}

resource "google_project_iam_member" "prod_img_svc_act_iam" {
    provider = "google.prod"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["prod"]}"
}

output "ci_svc_act_iam" {
    value = {
        test = ["${google_project_iam_member.test_ci_svc_act_iam.*.role}"],
        stage = ["${google_project_iam_member.stage_ci_svc_act_iam.*.role}"],
        prod = ["${google_project_iam_member.prod_ci_svc_act_iam.*.role}"],
    }
    sensitive = true
}

/****
***** FIXME: https://github.com/terraform-providers/terraform-provider-acme/issues/65
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
    depends_on = ["module.project_dns"]  // not all resources are direct
    name = "${module.project_dns.name_to_zone["domain"]}"
}

data "template_file" "domain_ns" {
    count = "4"
    template = "${substr(data.google_dns_managed_zone.domain.name_servers[count.index],
                         0,
                         length(data.google_dns_managed_zone.domain.name_servers[count.index]) - 1)}"
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
