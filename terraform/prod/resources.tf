
module "strongboxes" {
    providers = { google = "google" }
    source = "../modules/strongboxes"
    env_name_uuid = "${var.UUID}"
    readers = {
        test = ["${module.test_service_account.email}",],
        stage = ["${module.stage_service_account.email}"],
        prod= []
    }
    strongbox = "${local.self["STRONGBOX"]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

module "strong_unbox" {
    source = "../modules/strong_unbox"
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox = "${local.self["STRONGBOX"]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

/*
module "gateway" {
    source = "../modules/gateway"
    providers {
        google = "google"
    }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
*/
