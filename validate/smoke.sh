#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"
TEST_ENV="$1"
TF_TEST_DIRPATH="$SRC_DIR/terraform/$TEST_ENV"
BACKEND_FILEPATH="$TF_TEST_DIRPATH/backend.auto.tfvars"
RUNTIME_FILEPATH="$TF_TEST_DIRPATH/runtime.auto.tfvars"
RUNTIME_KEYS="UUID ENV_NAME SRC_VERSION TEST_SECRETS $(echo $TEST_ENV | tr [[:lower:]] [[:upper:]])_SECRETS"
RUNTIME_SKEYS="UUID CREDENTIALS SUSERNAME PROJECT REGION ZONE BUCKET UUID STRONGBOX STRONGKEY"

indent 4 "Checking basic $TEST_ENV env terraform target was executed"
for fname in \
    backend.auto.tfvars \
    runtime.auto.tfvars \
    .terraform/terraform.tfstate \
    .terraform/plugins/linux_amd64/lock.json
do
    non_empty_file 5 "$TF_TEST_DIRPATH/$fname"
done

indent 4 "Checking CREDENTIALS points at readable file"
CREDENTIALS="$(egrep -a -m 1 -o "^credentials = \".+\"" "$BACKEND_FILEPATH" | cut -d \" -f 2)"
[[ -r "$CREDENTIALS" ]] || \
    die "Unable to read credentials file at $CREDENTIALS" 12
CREDCONTENT=$(cat "$CREDENTIALS")
[[ -n "$CREDCONTENT" ]] || \
    die "Credentials file empty $CREDENTIALS" 13

indent 4 "Checking expected runtime secrets present"
for KEY in ENV_NAME SRC_VERSION $RUNTIME_KEYS
do
    indent 5 "Checking $KEY is present"
    egrep -q -a -m 1 "^$KEY = " $RUNTIME_FILEPATH || \
        die "Missing $KEY key in $RUNTIME_FILEPATH" 10
done

for KEY in $RUNTIME_SKEYS
do
    indent 5 "Checking nested $KEY is present"
    egrep -q -a -m -1 "^    $KEY = \".+\"" $RUNTIME_FILEPATH || \
        die "Missing nested $KEY key in $RUNTIME_FILEPATH" 11
done
