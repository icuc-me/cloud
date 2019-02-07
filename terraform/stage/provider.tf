provider "external" {
    version = "~> 1.0"
}

provider "null" {
    version = "~> 2.0"
}

provider "template" {
    version = "~> 2.0"
}

// Default for this environment

provider "google" {
    version = "~> 1.20"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
}

// Aliases for all environments

provider "google" {
    version = "~> 1.20"
    alias = "test"
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
}

provider "google" {
    version = "~> 1.20"
    alias = "stage"
    credentials = "${var.STAGE_SECRETS["CREDENTIALS"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    region = "${var.STAGE_SECRETS["REGION"]}"
    zone = "${var.STAGE_SECRETS["ZONE"]}"
}

provider "google" {
    version = "~> 1.20"
    alias = "prod"
    credentials = "${var.PROD_SECRETS["CREDENTIALS"]}"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    region = "${var.PROD_SECRETS["REGION"]}"
    zone = "${var.PROD_SECRETS["ZONE"]}"
}
