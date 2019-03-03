module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
    strongbox = "${local.is_prod == 1
                   ? local.self["STRONGBOX"]
                   : local.mock_strongbox}"
    strongkeys = "${local.strongkeys}"
    force_destroy = "${local.is_prod == 1
                       ? 0
                       : 1}"
}

output "strongbox_uris" {
    value = "${module.strongboxes.uris}"
    sensitive = true
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    // Actual strongbox URI (not mock)
    strongbox_uri = "${local.self["STRONGBOX"]}/${basename(module.strongboxes.uris[var.ENV_NAME])}"
    strongkey = "${local.self["STRONGKEY"]}"
}

output "strongbox_contents" {
    value = "${module.strong_unbox.contents}"
    sensitive = true
}

module "mock_strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    // Mock strongbox unless env == prod
    strongbox_uri = "${module.strongboxes.uris[var.ENV_NAME]}"
    strongkey = "${local.strongkeys[var.ENV_NAME]}"
}

output "mock_strongbox_contents" {
    value = "${module.mock_strong_unbox.contents}"
    sensitive = true
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
