variable "roles_members" {
    description = "Format accepted by map_csv module"
}

variable "create" {
    description = "Create and manage the IAM roles 1 or not 0 (default)"
    default = "0"
}

module "roles_members" {
    source = "../map_csv"
    string = "${var.roles_members}"
}

// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
resource "google_project_iam_binding" "roles_members_bindings" {
    count = "${var.create != 0
               ? length(module.roles_members.keys)
               : 0}"
    role = "${element(module.roles_members.keys, count.index)}"
    members = ["${element(module.roles_members.values, count.index)}"]
}
