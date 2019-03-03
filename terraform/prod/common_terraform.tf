
# From CLI -backend-config="${ENV_NAME}-backend.auto.tfvars"
terraform {
    backend "gcs" {}
    required_version = "~> 0.11"
}
