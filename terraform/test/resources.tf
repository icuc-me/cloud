
module "strongboxes" {
    providers = { google = "google" }
    source = "./modules/strongboxes"
    env_name_uuid = "${var.UUID}"
    readers = {
        test = [],
        stage = [],
        prod= []
    }
    strongbox = "${local.self["STRONGBOX"]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

/*
module "strong_unbox" {
    source = "./modules/strong_unbox"
    credentials = "${local.self["CREDENTIALS"]}"
    // Only way to add a dependency to a module block
    strongbox = "${0 == 0
                   ? local.self["STRONGBOX"]
                   : module.strongboxes.uris[var.ENV_NAME]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

module "gateway" {
    source = "./modules/gateway"
    providers {
        google = "google"
    }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
*/
