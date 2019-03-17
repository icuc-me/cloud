
variable "string" {
    description = "The string to process into a map of CSV string lists"
}

variable "m_delim" {
    description = "The delimiter which separates the map key/value pairs"
    default = ";"
}

variable "kv_delim" {
    description = "The delimiter which separates keys from values"
    default = "="
}

variable "s_delim" {
    description = "The delimiter which separates each string in map values"
    default = ","
}

module "kvs" {
    source = "../items_count"
    string = "${var.string}"
    delim = "${var.m_delim}"
}

data "template_file" "keys" {
    count = "${module.kvs.count}"
    template = "${trimspace(element(split(var.kv_delim,
                                          module.kvs.items[count.index]),
                                    0))}"
}

data "template_file" "values" {
    count = "${module.kvs.count}"
    template = "${trimspace(element(split(var.kv_delim,
                                          module.kvs.items[count.index]),
                                    1))}"
}

locals {
    unique_keys = ["${compact(distinct(data.template_file.keys.*.rendered))}"]
    unique_count = "${length(local.unique_keys)}"
}

// There may be duplicate keys
data "template_file" "keys_values" {
    count = "${local.unique_count}"
    template = "${join(var.s_delim, matchkeys(data.template_file.values.*.rendered,
                                              data.template_file.keys.*.rendered,
                                              list(local.unique_keys[count.index])))}"
}

output "transmogrified" {
    value = "${zipmap(local.unique_keys, data.template_file.keys_values.*.rendered)}"
}

output "keys" {
    value = ["${local.unique_keys}"]
}

output "values" {
    value = ["${data.template_file.keys_values.*.rendered}"]
}
