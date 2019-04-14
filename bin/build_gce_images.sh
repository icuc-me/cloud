#!/bin/bash

set -e

source $(dirname $0)/lib.sh

edie() {
    die "Expecting \$$1 to be set" 4
}

type -P packer &> /dev/null || die "Expecting packer to be available in \$PATH" 1
[[ -n "$CI" ]] || die "Expecting \$CI to be non-empty" 2
[[ "$CI" == "true" ]] || die "Expecting \$CI to be true: $CI" 3
[[ -n "$GCE_CREDENTIALS" ]] || edie GCE_CREDENTIALS
[[ -n "$SERVICE_ACCOUNT_EMAIL" ]] || edie SERVICE_ACCOUNT_EMAIL
[[ -n "$GCE_SSH_USERNAME" ]] || edie GCE_SSH_USERNAME
[[ -n "$GCP_PROJECT_ID" ]] || edie GCP_PROJECT_ID
[[ -n "$GCP_ZONE" ]] || edie GCP_ZONE
[[ -n "$VPC_NET" ]] || edie VPC_NET
[[ -n "$IMAGE_PROJECT_ID" ]] || edie IMAGE_PROJECT_ID
[[ -n "$BUILT_IMAGE_SUFFIX" ]] || edie BUILT_IMAGE_SUFFIX
[[ -n "$CI_IMAGE_NAME" ]] || edie CI_IMAGE_NAME

cd "$SRC_DIR"
SCMD='rm -f /$HOME/.gac.json'
trap 'rm -f /$HOME/.gac.json' EXIT
echo "$GCE_CREDENTIALS" > "/$HOME/.gac.json"
unset -v GCE_CREDENTIALS
export GOOGLE_APPLICATION_CREDENTIALS="/$HOME/.gac.json"
export PACKER_CACHE_DIR="/tmp"

cd "${SRC_DIR}/packer"
python3 -c 'import json,yaml; json.dump( yaml.load(open("images.yml").read(),Loader=yaml.SafeLoader), open("images.json","w"));'

export TMPDIR=/var/tmp
export PACKER_CACHE_DIR=/var/tmp/packer_cache
export CHECKPOINT_DISABLE=1
PACKER_DEBUG=1 packer build \
    -var GCE_SSH_USERNAME=$GCE_SSH_USERNAME \
    -var GCP_PROJECT_ID=$GCP_PROJECT_ID \
    -var GCP_ZONE=$GCP_ZONE \
    -var VPC_NET=$VPC_NET \
    -var SERVICE_ACCOUNT_EMAIL=$SERVICE_ACCOUNT_EMAIL \
    -var IMAGE_PROJECT_ID=$IMAGE_PROJECT_ID \
    -var BUILT_IMAGE_SUFFIX=$BUILT_IMAGE_SUFFIX \
    -var CI_IMAGE_NAME=$CI_IMAGE_NAME \
    -var SRC_DIR=$SRC_DIR \
    images.json

$SCMD

[[ -r "packer-manifest.json" ]] || die "Expecting to find output manifest" 5

echo "########################################"
python3 -c 'import sys,yaml,json; print(yaml.dump(json.load(open("packer-manifest.json")), sys.stdout));'
echo "########################################"
