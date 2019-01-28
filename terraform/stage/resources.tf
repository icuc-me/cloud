
// Required as workaround until https://github.com/hashicorp/terraform/issues/4149
resource "null_resource" "phase_1" {
    depends_on = [
        "module.test_service_account",  // NEEDS PER-ENV MODIFICATION
        "module.stage_service_account",
        // "module.prod_service_account",
    ]
}

module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
    strongbox = "${local.is_prod == 1
                   ? local.self["STRONGBOX"]
                   : local.mock_strongbox}"
    strongkeys = "${local.strongkeys}"
    readers = "${local.strongbox_readers}"
    force_destroy = "${local.is_prod == 1
                       ? 0
                       : 1}"
}

resource "null_resource" "phase_2" {
    depends_on = [
        "module.strongboxes"
    ]
}

resource "null_resource" "preload" {
    depends_on = [
        "null_resource.phase_1",
        "null_resource.phase_2"
    ]
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox = "${format("%s/%s",
                          local.self["STRONGBOX"],
                          module.strongboxes.filenames[var.ENV_NAME])}"
    strongkey = "${local.self["STRONGKEY"]}"
}

module "gateway" {
    source = "./modules/gateway"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
