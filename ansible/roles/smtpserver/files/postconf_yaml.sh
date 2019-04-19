#!/bin/bash

set -e

# This script is called by the ansible 'script' module.  It
# runs on the subject host as a temporary file, after being
# transfered.  When stdin is Normally expected to be run w/o arguments,
# unless under unittest conditions.

if [[ -r "$1" ]] # Support unittesting this script
then
    INPUT_CMD="cat $1"
else  # Normal use
    INPUT_CMD="postconf -n"
fi

# YAML document start
echo "---"
echo ""

# Ansible YAML parser expects the document to be a hash (not a list),
# and the role expects this key.
echo "postfix_configuration:"

# Filter $INPUT_CMD's output in 'postconf -n' or compatible format. A
# series of "key = value" lines.  Each is rewritten as a "key: 'value'"
# in YAML hash syntax on stdout.
$INPUT_CMD | while read key eq value; do
    if [[ -z "$key" ]] || [[ "$eq" != "=" ]]; then continue; fi
    value=$(echo "$value" | sed -r -e "s/'/\\\'/g")
    echo "    $key: '$value'"
done
