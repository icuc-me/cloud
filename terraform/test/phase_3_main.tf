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
    mock_strongbox_contents = "${data.terraform_remote_state.phase_2.mock_strongbox_contents}"
}

module "test_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.test" }
    susername = "${local.is_prod == 1
                   ? local.strongbox_contents["ci_susername"]
                   : local.mock_strongbox_contents["ci_susername"]}"
    sdisplayname = "${local.is_prod == 1
                      ? local.strongbox_contents["ci_suser_display_name"]
                      : local.mock_strongbox_contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "project_networks" {
    source = "./modules/project_networks"
    providers { google = "google" }
    env_uuid = "${var.UUID}"
    default_tcp_ports = ["${compact(split(",",local.strongbox_contents["tcp_fw_ports"]))}"]
    default_udp_ports = ["${compact(split(",",local.strongbox_contents["udp_fw_ports"]))}"]
}

output "public_network" {
    value = "${module.project_networks.public}"
    sensitive = true
}

output "private_network" {
    value = "${module.project_networks.private}"
    sensitive = true
}

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

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
