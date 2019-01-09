#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"

TF_TEST_DIRPATH="$SRC_DIR/terraform/test"

indent 4 "Checking basic test env terraform target was executed"
for fname in \
    backend.auto.tfvars \
    runtime.auto.tfvars \
    .terraform/terraform.tfstate \
    .terraform/plugins/linux_amd64/lock.json
do
    non_empty_file 5 "$TF_TEST_DIRPATH/$fname"
done
