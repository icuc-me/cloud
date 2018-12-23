

# From provider.auto.tfvars and backend.auto.tfvars
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

# From command-line
variable "env_name" {
    description = "Name of environment to operating in (test, stage, prod)"
}
