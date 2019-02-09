variable "env_uuid" {
    description = "The UUID value associated with the current environment."
}

variable "count" {
    description = "The number of CIDR subnetworks to generate"
}

data "external" "cidrs" {
    program = ["python3", "${path.module}/gencidrs.py"]
    query = {
        count = "${var.count}"
        seed_string = "${var.env_uuid}_${var.count}"
    }
}

output "set" {
    value = ["${split(",", data.external.cidrs.result.csv)}"]
    sensitive = true
}
