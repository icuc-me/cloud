
/**** WARNING: This is authorative for the role ****/

variable "project" {
    description = "GCE project name to manage"
}

variable "role_members" {
    type = "map"
    description = "Mapping of role-names to list of members for that role"
}

locals {
    roles = ["${keys(var.role_members)}"]
    check_val1 = "${contains(local.roles, "roles/owner") == true
                    ? 0
                    : 1}"
    check_val2 = "${contains(local.roles, "roles/editor") == true
                    ? 0
                    : 1}"
    role_count = "${length(local.roles) * local.check_val1 * local.check_val2}"
}

// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
resource "google_project_iam_binding" "iam_bindings" {
  count = "${local.role_count}"
  project = "${var.project}"
  role    = "${element(local.roles, count.index)}"
  members  = ["${lookup(var.role_members, element(local.roles, count.index))}"]
}
