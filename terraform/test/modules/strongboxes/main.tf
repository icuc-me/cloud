
provider "google" {}

variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_acl.html#role_entity
variable "acls" {
    description = "Mapping of env_name to list of role_entity ACL values"
    type = "map"
}

locals {
    env_names = ["test", "stage", "prod"]  // order is significant

    // one bucket for this env, and one for each lower level env
    strongbox_count = "${var.env_name == "prod" ? 3 : var.env_name == "stage" ? 2 : 1}"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket.html
resource "google_storage_bucket" "strongbox" {
    count = "${local.strongbox_count}"  // index into env_names
    name = "${element(local.env_names, count.index)}${uuid()}"
    // prod bucket destruction should fail
    force_destroy = "${var.env_name == "prod" ? "false" : "true"}"
    lifecycle = {
        ignore_changes = "name"
    }
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_acl.html
resource "google_storage_bucket_acl" "strongbox_acl" {
    count = "${local.strongbox_count}"
    bucket = "${google_storage_bucket.strongbox.*.name[count.index]}"
    role_entity = ["${var.acls[var.env_name]}"]
}

// Form list of environment names to include uri's for in output
locals {
    // Workaround, smuggle list through conditional (fixed in 0.12)
    test_envs  = "${join(",", slice(local.env_names, 0, 1))}"
    stage_envs = "${join(",", slice(local.env_names, 0, 2))}"
    prod_envs  = "${join(",", slice(local.env_names, 0, 3))}"
    _envs = "${var.env_name == "prod"
               ? local.prod_envs
               : var.env_name == "stage"
                 ? local.stage_envs
                 : local.test_envs}"
}

output "uris" {
    value = "${zipmap(split(",", local._envs), google_storage_bucket.strongbox.*.url)}"
    sensitive = true
}
