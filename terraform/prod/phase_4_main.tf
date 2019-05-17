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
}

// VPC subnetworks and firewalls required by all instances and containers
module "project_networks" {
    source = "./modules/project_networks"
    providers { google = "google" }
    env_uuid = "${var.UUID}"
    test_project = "${local.is_prod == 1
                      ? var.TEST_SECRETS["PROJECT"]
                      : ""}"
    stage_project = "${local.is_prod == 1
                       ? var.STAGE_SECRETS["PROJECT"]
                       : ""}"
    prod_project = "${local.is_prod == 1
                      ? var.PROD_SECRETS["PROJECT"]
                      : ""}"
    public_tcp_ports = ["${compact(split(",",local.strongbox_contents["tcp_fw_ports"]))}"]
    public_udp_ports = ["${compact(split(",",local.strongbox_contents["udp_fw_ports"]))}"]
}

output "automatic_network" {
    value = "${module.project_networks.automatic[var.ENV_NAME]}"
    sensitive = true
}

output "public_network" {
    value = "${module.project_networks.public}"
    sensitive = true
}

output "private_network" {
    value = "${module.project_networks.private}"
    sensitive = true
}

// Main firewall and VPN for filtering external traffic to internal subnetwork
module "gateway" {
    source = "./modules/gateway"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
    public_subnetwork = "${module.project_networks.public["subnetwork_name"]}"
    private_subnetwork = "${module.project_networks.private["subnetwork_name"]}"
}

output "gateway_external_ip" {
    value = "${module.gateway.external_ip}"
    sensitive = true
}

output "gateway_private_ip" {
    value = "${module.gateway.private_ip}"
    sensitive = true
}

locals {
    domain = "${local.is_prod == 1
                ? local.strongbox_contents["fqdn"]
                : join(".", list(var.UUID, local.strongbox_contents["fqdn"]))}"
    legacy_domains = "${split(",", local.strongbox_contents["legacy_domains"])}"
    test_legacy_domain_fmt = "%s.${local.domain}"
}

data "template_file" "legacy_domains" {
    count = "${length(local.legacy_domains)}"
    template = "${local.is_prod == 1
                  ? local.legacy_domains[count.index]
                  : format(local.test_legacy_domain_fmt,
                           local.legacy_domains[count.index])}"
}

module "project_dns" {
    source = "./modules/project_dns"
    providers {
        google.test = "google.test"
        google.stage = "google.stage"
        google.prod = "google.prod"
    }
    domain = "${local.domain}"
    cloud_subdomain = "${local.strongbox_contents["cloud_subdomain"]}"
    site_subdomain = "${local.strongbox_contents["site_subdomain"]}"
    legacy_domains = "${data.template_file.legacy_domains.*.rendered}"
    gateway = "${module.gateway.external_ip}"
    project = "${local.self["PROJECT"]}"
    env_name = "${var.ENV_NAME}"
}

output "fqdn" {
    value = "${module.project_dns.fqdn}"
    sensitive = true
}

output "zone" {
    value = "${module.project_dns.zone}"
    sensitive = true
}


output "ns" {
    value = "${module.project_dns.ns}"
    sensitive = true
}

output "name_to_zone" {
    value = "${module.project_dns.name_to_zone}"
    sensitive = true
}

output "gateways" {
    value = "${module.project_dns.gateways}"
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
    site_fqdn = "${local.strongbox_contents["cloud_subdomain"]}.${local.strongbox_contents["fqdn"]}"
    cloud_fqdn = "${local.strongbox_contents["site_subdomain"]}.${local.strongbox_contents["fqdn"]}"
    _sans = ["${formatlist(local.wildfmt,
                           concat(list(local.strongbox_contents["fqdn"],
                                       local.site_fqdn,
                                       local.cloud_fqdn),
                                  data.template_file.legacy_domains.*.rendered,
                                  ))}"]
    sans = ["${concat(data.template_file.legacy_domains.*.rendered,
                      local._sans)}"]
}

resource "acme_certificate" "fqdn_certificate" {
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    common_name = "${local.strongbox_contents["fqdn"]}"
    subject_alternative_names = ["${local.sans}"]
    key_type = "${tls_private_key.cert_private_key.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 20 : 0}"
    certificate_p12_password = "${local.strongkeys[var.ENV_NAME]}"

    dns_challenge {
        provider = "gcloud"
        // decouple from default nameservers on runtime host
        recursive_nameservers = ["8.8.8.8:53", "8.8.4.4:53"]  // docs say they need ports
        config {
            // 5 & 180 (default) too quick & slow, root entry needs more time
            GCE_POLLING_INTERVAL = "10"
            GCE_PROPAGATION_TIMEOUT = "300"
            GCE_PROJECT = "${local.self["PROJECT"]}"
            GCE_SERVICE_ACCOUNT_FILE = "${local.self["CREDENTIALS"]}"
        }
    }
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
