
variable "env_name" {
    description = "Name of the current environment (test, stage, prod)"
}

variable "roles_members" {
    description = "Encoded map of list of strings.  Maps separated by ';', Key/value separated by '=', value list items separated by ','."
}

locals {
    roles_members = ["${compact(split(";", trimspace(var.roles_members)))}"]
    length = "${length(local.roles_members)}"
}

module "roles_members" {
    source = "../roles_members"
    roles_members = ["${local.roles_members}"]
    length = "${local.length}"
}


// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
resource "google_project_iam_binding" "roles_members_bindings" {
    count = "${var.env_name == "test" || var.env_name == "stage"
               ? 0
               : local.length}"
    role = "${element(module.roles_members.roles, count.index)}"
    members = ["${split(",", trimspace(element(module.roles_members.members, count.index)))}"]
}

output "roles" {
    value = ["${module.roles_members.roles}"]
}

output "members" {
    value = ["${module.roles_members.members}"]
}
