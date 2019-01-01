

# From provider.auto.tfvars, backend.auto.tfvars, uuid.auto.tfvars
variable "credentials" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#credentials"
}
variable "project" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#project"
}
variable "region" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#region"
}
variable "zone" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#zone"
}
variable "bucket" {
    description = "https://www.terraform.io/docs/backends/types/gcs.html#configuration-variables"
}
variable "env_uuid" {
    description = "Unique Name associated but also loosely associated to env_name"
}

# From runtime.auto.tfvars
variable "env_name" {
    description = "Name of environment to operating in (test, stage, prod)"
}

variable "src_version" {
    description = "The version string of the source repository at runtime"
}
