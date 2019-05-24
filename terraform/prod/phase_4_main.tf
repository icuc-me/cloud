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
    admin_username = "${local.strongbox_contents["admin_username"]}"
    admin_sshkey = "${local.strongbox_contents["admin_sshkey"]}"
    setup_data = "${local.strongbox_contents["gateway_setup_data"]}"
}

output "cloud_gateway_external_ip" {
    value = "${module.gateway.external_ip}"
    sensitive = true
}

output "cloud_gateway_private_ip" {
    value = "${module.gateway.private_ip}"
    sensitive = true
}

locals {
    e = ""
    c = ","
    d = "."
    t = "%s"
    // see modules/project_dns/notes.txt
    test_fqdn_parent = "${join(local.d, list("test", local.strongbox_contents["fqdn"]))}"
    test_fqdn = "${join(local.d, list(var.UUID, local.test_fqdn_parent))}"
    test_glue_fqdn = "${local.is_test == 1
                        ? local.test_fqdn_parent
                        : local.e}"
    // assumed to be shortnames unless prod-environment
    legacy_domains = ["${split(local.c, local.strongbox_contents["legacy_domains"])}"]
    legacy_domain_fmt = "${local.is_prod == 1
                           ? local.t
                           : join(local.d, list(local.t, local.test_glue_fqdn))}"
    canonical_legacy_domains = ["${formatlist(local.legacy_domain_fmt, local.legacy_domains)}"]
}

module "project_dns" {
    source = "./modules/project_dns"
    providers {  // N/B: In test & stage, these are NOT the actual named providers!
        google.test = "google.test"
        google.stage = "google.stage"
        google.prod = "google.prod"
    }
    glue_fqdn = "${local.test_glue_fqdn}"
    domain_fqdn = "${local.is_test == 1
                     ? local.test_fqdn
                     : local.strongbox_contents["fqdn"]}"
    legacy_domains = ["${local.canonical_legacy_domains}"]
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
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

data "template_file" "legacy_shortnames" {
    count = "${length(local.canonical_legacy_domains)}"
    template = "${element(split(local.d, element(local.canonical_legacy_domains, count.index)), 0)}"
}

data "template_file" "legacy_zones" {
    count = "${length(local.canonical_legacy_domains)}"
    template = "${lookup(module.project_dns.name_to_zone,
                         data.template_file.legacy_shortnames.*.rendered[count.index])}"
}

// Assumed that production environment deployment always happens behind the site gateway
module "site_gateway_ip" {
    source = "./modules/myip"
}

output "site_gateway_external_ip" {
    value = "${module.site_gateway_ip.ip}"
    sensitive = true
}

module "dns_records" {
    source = "./modules/dns_records"
    domain_zone = "${module.project_dns.zone}"
    // FIXME
    gateways = "${map(
        lookup(module.project_dns.name_to_zone, "cloud"), module.gateway.external_ip,
        lookup(module.project_dns.name_to_zone, "site"), module.site_gateway_ip.ip
    )}"
    service_destinations {
        mail = "${lookup(module.project_dns.name_to_zone, "site")}"
        www = "${lookup(module.project_dns.name_to_zone, "site")}"
        file = "${lookup(module.project_dns.name_to_zone, "site")}"
    }
    managed_zones = ["${concat(data.template_file.legacy_zones.*.rendered,
                               list(lookup(module.project_dns.name_to_zone, "cloud"),
                                    lookup(module.project_dns.name_to_zone, "site")))}"]
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
    site_fqdn = "site.${local.strongbox_contents["fqdn"]}"
    cloud_fqdn = "cloud.${local.strongbox_contents["fqdn"]}"
    _sans = ["${formatlist(local.wildfmt,
                           concat(list(local.strongbox_contents["fqdn"],
                                       local.site_fqdn,
                                       local.cloud_fqdn),
                                  local.canonical_legacy_domains,
                                  ))}"]
    sans = ["${concat(local.canonical_legacy_domains,
                      local._sans)}"]
}

resource "acme_certificate" "fqdn_certificate" {
    depends_on = ["module.project_dns"]
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    common_name = "${local.strongbox_contents["fqdn"]}"
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
            GCE_PROJECT = "${local.self["PROJECT"]}"
            GCE_SERVICE_ACCOUNT_FILE = "${local.self["CREDENTIALS"]}"
        }
    }
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
