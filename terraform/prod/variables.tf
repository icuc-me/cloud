
# From top-level backend.auto.tfvars
variable "credentials" {}
variable "project" {}
variable "region" {}
variable "bucket" {}
variable "prefix" {}

# From top-level of runtime.auto.tfvars
variable "UUID" {
    type = "string"
    description = "Unique ID loosely associated with ENV_NAME"
}

# From runtime.auto.tfvars
variable "ENV_NAME" {
    type = "string"
    description = "Name of environment to operating in (test, stage, prod)"
}

variable "SRC_VERSION" {
    type = "string"
    description = "The version string of the source repository at runtime"
}

// N/B: Map variables cannot be nested, single-level deep only (as of v0.11.11)
variable "TEST_SECRETS" {
    type = "map"
    description = "Subordinate test environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = { // prevents lookup errors
        CREDENTIALS = ""
        SUSERNAME = ""
        PROJECT = ""
        STRONGBOX = ""
        STRONGKEY = ""
        REGION = ""
        ZONE = ""
        BUCKET = ""
        UUID = ""
    }
}

variable "STAGE_SECRETS" {
    type = "map"
    description = "Subordinate stage environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = {
        CREDENTIALS = ""
        SUSERNAME = ""
        PROJECT = ""
        STRONGBOX = ""
        STRONGKEY = ""
        REGION = ""
        ZONE = ""
        BUCKET = ""
        UUID = ""
    }
}

variable "PROD_SECRETS" {
    type = "map"
    description = "Subordinate prod environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = {
        CREDENTIALS = ""
        SUSERNAME = ""
        PROJECT = ""
        STRONGBOX = ""
        STRONGKEY = ""
        REGION = ""
        ZONE = ""
        BUCKET = ""
        UUID = ""
    }
}

locals {
    self = "${merge(var.PROD_SECRETS, local._src_version)}"
    _src_version = { SRC_VERSION = "${var.SRC_VERSION}" }
    mock_strongbox = "${local.self["STRONGBOX"]}_mock_${var.UUID}"  // uniqe for test env.
    strongbox = "${var.ENV_NAME != "prod"
                   ? local.mock_strongbox
                   : local.self["STRONGBOX"]}"
    strongbox_readers = {
        test = ["${module.test_service_account.email}",
                "${module.stage_service_account.email}"]
        stage = ["${module.stage_service_account.email}"]
        prod= []
    }
    strongkeys = {
        test = "${var.ENV_NAME == "test"
                  ? "TESTY-MC-TESTFACE"
                  : var.TEST_SECRETS["STRONGKEY"]}"
        stage = "${var.ENV_NAME == "test"
                   ? "STAGY-MC-STAGEFACE"
                   : var.STAGE_SECRETS["STRONGKEY"]}"
        prod = "${var.ENV_NAME == "test" || var.ENV_NAME == "stage"
                  ? "PRODY-MC-PRODFACE"
                  : var.PROD_SECRETS["STRONGKEY"]}"
    }
}
