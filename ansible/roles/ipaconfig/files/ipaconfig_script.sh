#!/bin/bash
# This script is managed by ansible, manual edits will be lost.
set -e

source "$(dirname $0)/ipaconfig_lib.sh"

FWDZONES=$(ipacmditem "Zone name" ipa dnszone-find --zone-active=true --forward-only)
[[ -n "$FWDZONES" ]] || die "No DNS forward zones found"
