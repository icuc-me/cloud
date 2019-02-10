
/**** TEST ****/
module "test_service_account" {
    source = "./modules/service_account"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    susername = "${var.TEST_SECRETS["SUSERNAME"]}"
}
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["test_roles_members_bindings"]}"
}


/**** STAGE ****/
// module "stage_service_account" {
//     source = "./modules/service_account"
//     providers { google = "google.stage" }
//     env_name = "${var.ENV_NAME}"
//     susername = "${var.STAGE_SECRETS["SUSERNAME"]}"
// }
// module "stage_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.stage" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${module.strong_unbox.contents["stage_roles_members_bindings"]}"
// }


/**** PROD ****/
// module "prod_service_account" {
//     source = "./modules/service_account"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     susername = "${var.PROD_SECRETS["SUSERNAME"]}"
// }
// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${module.strong_unbox.contents["prod_roles_members_bindings"]}"
// }

// Required as workaround until https://github.com/hashicorp/terraform/issues/4149
resource "null_resource" "preload" {
    depends_on = [
        // NEEDS PER-ENV MODIFICATION
        "module.test_service_account",
        // "module.stage_service_account",
        // "module.prod_service_account"
    ]
}

module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
    readers = "${local.strongbox_readers}"
    strongbox = "${local.is_prod == 1
                   ? local.self["STRONGBOX"]
                   : local.mock_strongbox}"
    strongkeys = "${local.strongkeys}"
    force_destroy = "${local.is_prod == 1
                       ? 0
                       : 1}"
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox_uri = "${local.self["STRONGBOX"]}/${module.strongboxes.filenames[var.ENV_NAME]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

module "project_networks" {
    source = "./modules/project_networks"
    providers { google = "google" }
    env_uuid = "${var.UUID}"
    default_tcp_ports = ["${compact(split(",",module.strong_unbox.contents["tcp_fw_ports"]))}"]
    default_udp_ports = ["${compact(split(",",module.strong_unbox.contents["udp_fw_ports"]))}"]
}

module "gateway" {
    source = "./modules/gateway"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
    public_subnetwork = "${module.project_networks.public["subnetwork_name"]}"
    private_subnetwork = "${module.project_networks.private["subnetwork_name"]}"
}
