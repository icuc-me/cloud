
variable "string" {
    description = "String of zero or more items separated by delim"
}

variable "delim" {
    description = "Delimeter used to separate items in string"
    default = ","
}

data "external" "items_count" {
    program = ["python3", "${path.module}/items_count.py"]
    query = {
        string = "${var.string}"
        delim = "${var.delim}"
    }
}

output "items" {
    value = ["${split(var.delim, data.external.items_count.result.items)}"]
}

output "count" {
    value = "${data.external.items_count.result.count}"
}
