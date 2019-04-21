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

module "project_dns" {
    source = "./modules/project_dns"
    providers { google = "google" }
    private_network = "${module.project_networks.private["network_link"]}"
    testing = "${local.is_prod == 1
                 ? ""
                 : var.UUID }"
    public_fqdn = "${local.strongbox_contents["fqdn"]}"
}

output "dom_ns" {
    value = "${module.project_dns.dom_ns}"
    sensitive = true
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
