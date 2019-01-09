

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

variable "TEST_SECRETS" {
    type = "map"
    description = "Subordinate test environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = {}
}

variable "STAGE_SECRETS" {
    type = "map"
    description = "Subordinate stage environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = {}
}

variable "PROD_SECRETS" {
    type = "map"
    description = "Subordinate prod environment: CREDENTIALS, SUSERNAME, PROJECT, REGION, ZONE, BUCKET, and UUID values.  Note: Environment name keys are capitalized."
    default = {}
}
