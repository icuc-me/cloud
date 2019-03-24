
variable "k_csv" {
    description = "String of zero or more items separated by delim, item count matching v_csv"
}

variable "v_csv" {
    description = "String of zero or more items separated by delim, item count matching k_csv"
}

variable "v_re" {
    description = "Regular expression used to exclude matching items from v_csv"
}

variable "delim" {
    description = "Delimeter used to separate items in string"
    default = ","
}

data "external" "filter_parallel" {
    program = ["python3", "${path.module}/filter_parallel.py"]
    query = {
        k_csv = "${var.k_csv}"
        v_csv = "${var.v_csv}"
        delim = "${var.delim}"
        v_re = "${var.v_re}"
    }
}

output "keys" {
    value = ["${split(var.delim, data.external.filter_parallel.result.k_csv)}"]
}

output "values" {
    value = ["${split(var.delim, data.external.filter_parallel.result.v_csv)}"]
}

output "count" {
    value = "${data.external.filter_parallel.result.count}"
}
