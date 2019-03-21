#!/bin/bash

set -e
source $(dirname $0)/lib.sh

[[ "${CI}" == "true" ]] || die "The script $(basename $0) is only intended for us under CI." 1
ENVS="$(env | grep '^CIRRUS')" || die "The script requires all CI environment variables to be set" 2
[[ -d "$CIRRUS_WORKING_DIR" ]] || die "Not a directory: $CIRRUS_WORKING_DIR" 3

echo "Select environment variables:"
echo -e "PATH=$PATH\nVERSION=$VERSION\nIMG_FQIN=$IMG_FQIN\nIMG_TAG=$IMG_TAG
REG_NS=$REG_NS\nIMG_NAME=$IMG_NAME\nIMG_FQIN=$IMG_FQIN\n
TEST_IMG_TAG=$TEST_IMG_TAG\nIMG_TAG=$IMG_TAG\nVALID_FQIN=$VALID_FQIN
$(go env)
$ENVS" | sort -u

echo "Configuring credentials"
bin/env_file.sh TEST_SECRETS "$CIRRUS_WORKING_DIR/secrets/test-secrets.sh"
unset TEST_SECRETS
bin/env_file.sh TEST_CREDS "$CIRRUS_WORKING_DIR/secrets/50bdcb31cd804734a41ad420bc35fae7.json"
unset TEST_CREDS

echo "Recovering cached go directories"
mkdir -p "$(go env GOPATH)"
rsync --recursive --links --safe-links --sparse "/usr/src/go/" "$(go env GOPATH)"
mkdir -p "$(go env GOCACHE)"
rsync --recursive --links --safe-links --sparse "/var/cache/go/" "$(go env GOCACHE)"
