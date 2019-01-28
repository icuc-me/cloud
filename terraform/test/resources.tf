
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

// Required as workaround until https://github.com/hashicorp/terraform/issues/4149
resource "null_resource" "preload" {
    depends_on = [
        "module.test_service_account",  // NEEDS PER-ENV MODIFICATION
        "module.strongboxes"
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
