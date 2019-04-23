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
    providers {
        test.google = "test.google",
        stage.google = "stage.google",
        prod.google = "prod.google"
    }
    base_fqdn = "${local.strongbox_contents["fqdn"]}"
    testing = "${local.is_prod == 1
                 ? ""
                 : var.UUID }"
    cloud_subdomain = "${local.strongbox_contents["cloud_subdomain"]}"
    site_subdomain = "${local.strongbox_contents["site_subdomain"]}"
    gateway = "${module.gateway.external_ip}"
}

output "dns_data" {
    value = "${module.project_dns.dns_data}"
    #sensitive = true
}

// ref: https://www.terraform.io/docs/providers/acme/r/registration.html
resource "tls_private_key" "reg_private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.reg_private_key.private_key_pem}"
  email_address   = "${local.strongbox_contents["acme_reg_ename"]
                      }@${local.strongbox_contents["fqdn"]}"
}

resource "tls_private_key" "cert_private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "acme_certificate" "certificate" {
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    common_name = "${local.strongbox_contents["fqdn"]}"
    subject_alternative_names = ["*.${local.strongbox_contents["fqdn"]}"]
    key_type = "${tls_private_key.cert_private_key.rsa_bits}"  // bits mean rsa
    min_days_remaining = "${local.is_prod == 1 ? 20 : 0}"
    certificate_p12_password = "${local.strongkeys[var.ENV_NAME]}"

    dns_challenge {
        provider = "gcloud"
        // decouple from default nameservers on runtime host
        recursive_nameservers = ["${formatlist("%s:53",
                                               split(",",
                                                     module.project_dns.dns_data["fqdn_ns"]))}"]
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
