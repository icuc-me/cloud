#!/bin/bash

# This script is intended to be called by the Makefile, not humans.

ENV_NAME=$1
SUSERNAME=$2

[[ -n "$ENV_NAME" ]] || exit 1
[[ -n "$SUSERNAME" ]] || exit 2
[[ -r "${ENV_NAME}-backend.auto.tfvars" ]] || exit 3
[[ -r "provider.auto.tfvars" ]] || exit 4

tfvar_to_yml() {
    [[ -n "$1" ]] || exit 50
    echo -n "$1" | sed -re 's/ *= */: /g'
}

echo -e '---\n'
for filename in "${ENV_NAME}-backend.auto.tfvars" "provider.auto.tfvars" "${ENV_NAME}-uuid.auto.tfvars"
do
    dict="terraform_$(echo $filename | cut -d - -f 2 | cut -d . -f 1)"
    echo -e "\n${dict}:"
    cat "$filename" | while read LINE; do
        echo "    "`tfvar_to_yml "$LINE"`
    done
done
