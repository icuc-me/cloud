
provider "acme" {
    version = "~> 1.3"
    server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

// Default for this environment

provider "google" {
    version = "~> 2.5"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

// Aliases for all environments

provider "google" {
    version = "~> 2.5"
    alias = "test"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

provider "google" {
    version = "~> 2.5"
    alias = "stage"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

// THE ALIASES BELOW ARE FAKE - FOR TESTING

provider "google" {
    version = "~> 2.5"
    alias = "prod"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}
