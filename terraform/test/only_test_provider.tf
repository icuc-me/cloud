// Default for this environment

provider "google" {
    version = "~> 2.2"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

// Aliases for all environments

provider "google" {
    version = "~> 2.2"
    alias = "test"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

// THE ALIASES BELOW ARE FAKE - FOR TESTING

provider "google" {
    version = "~> 2.2"
    alias = "stage"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}

provider "google" {
    version = "~> 2.2"
    alias = "prod"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
    scopes = ["${local.google_scopes}"]
}
