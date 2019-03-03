
variable "keys_values" {
    type = "list"
    description = "List of key/values items separated by '=', value items separated by ','."
}

variable "length" {
    description = "Number of entries in keys_values list."
}

// list of maps, separating key strings from value strings

data "template_file" "keys" {
    count = "${var.length}"
    template = "${trimspace(element(split("=",
                                          element(var.keys_values,
                                                  count.index)),
                                    0))}"
}

data "template_file" "values" {
    count = "${var.length}"
    template = "${trimspace(element(split("=",
                                          element(var.keys_values,
                                                  count.index)),
                                    1))}"
}

output "keys" {
    value = ["${data.template_file.keys.*.rendered}"]
}

output "values" {
    value = ["${data.template_file.values.*.rendered}"]
}
