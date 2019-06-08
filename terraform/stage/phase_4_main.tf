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

locals {
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"
    name_to_zone = "${data.terraform_remote_state.phase_3.name_to_zone}"
    legacy_shortnames = ["${data.terraform_remote_state.phase_3.legacy_shortnames}"]
    canonical_legacy_domains = ["${data.terraform_remote_state.phase_3.canonical_legacy_domains}"]
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

resource "tls_private_key" "admin" {
  algorithm   = "RSA"
  ecdsa_curve = "4096"
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
    admin_sshkey = "${tls_private_key.admin.private_key_pem}"
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

resource "local_file" "admin_public_key" {
    sensitive_content = "${tls_private_key.admin.public_key_pem}"
    filename = "${path.root}/output_files/${local.strongbox_contents["admin_username"]}.key.pub"
}

resource "local_file" "admin_private_key" {
    sensitive_content = "${tls_private_key.admin.private_key_pem}"
    filename = "${path.root}/output_files/${local.strongbox_contents["admin_username"]}.key"
}

data "template_file" "legacy_zones" {
    count = "${length(local.legacy_shortnames)}"
    template = "${lookup(local.name_to_zone,
                         local.legacy_shortnames[count.index])}"
}

// Assumed that production environment deployment always happens behind the site gateway
module "site_gateway_ip" {
    source = "./modules/myip"
}

output "site_gateway_external_ip" {
    value = "${module.site_gateway_ip.ip}"
    sensitive = true
}

locals {
    gateways = "${map(lookup(local.name_to_zone, "cloud"), module.gateway.external_ip,
                      lookup(local.name_to_zone, "site"), module.site_gateway_ip.ip)}"
}

module "dns_records" {
    source = "./modules/dns_records"
    domain_zone = "${lookup(local.name_to_zone, "domain")}"
    gateways = "${local.gateways}"
    gateway_count = "2"
    service_destinations {
        mail = "${lookup(local.name_to_zone, "site")}"
        www = "${lookup(local.name_to_zone, "site")}"
        file = "${lookup(local.name_to_zone, "site")}"
    }
    managed_zones = ["${concat(data.template_file.legacy_zones.*.rendered,
                               list(lookup(local.name_to_zone, "cloud"),
                                    lookup(local.name_to_zone, "site")))}"]
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
