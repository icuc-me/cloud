
variable "roles_members" {
    type = "list"
    description = "List of key/values items separated by '=', value items separated by ','."
}

variable "length" {
    description = "Number of entries in roles_members list."
}

// list of maps, separating key strings from value strings

data "template_file" "roles" {
    count = "${var.length}"
    template = "${trimspace(element(split("=",
                                          element(var.roles_members,
                                                  count.index)),
                                    0))}"
}

data "template_file" "members" {
    count = "${var.length}"
    template = "${trimspace(element(split("=",
                                          element(var.roles_members,
                                                  count.index)),
                                    1))}"
}

output "roles" {
    value = ["${data.template_file.roles.*.rendered}"]
}

output "members" {
    value = ["${data.template_file.members.*.rendered}"]
}
