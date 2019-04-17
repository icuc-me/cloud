#!/bin/bash

set -e

source $(dirname $0)/lib.sh

[[ "$VERSION_MAJ" -gt "0" ]] || \
    die "Refusing to tag ephemeral version with 'latest': $VERSION_MAJ" 38

[[ "$(type -P skopeo)" ]] || \
    die "Cannot find skopeo binary" 39

reg_login

for name in "$BASE_IN" "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
do
    echo "Tagging '$REG_NS/$name:$IMG_TAG' -> 'latest'"
    sudo skopeo copy "docker://$REG_NS/$name:$IMG_TAG" "docker://$REG_NS/$name:latest"
done
