

module "strongboxes" {
    providers = { google = "google" }
    source = "./modules/strongboxes"
    env_name_uuid = "${var.UUID}"
    readers = {test = [], stage = [], prod= []}
    strongbox = "${var.TEST_SECRETS["STRONGBOX"]}"
    strongkey = "${var.TEST_SECRETS["STRONGKEY"]}"
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    strongbox = "${var.TEST_SECRETS["STRONGBOX"]}"
    strongkey = "${var.TEST_SECRETS["STRONGBOX"]}"
}

module "gateway" {
    source = "./modules/gateway"
    providers {
        google = "google"
    }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
