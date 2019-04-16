#!/bin/bash

set -e

source $(dirname $0)/lib.sh

[[ "$VERSION_MAJ" -ne "0" ]] || [[ "$IMG_TAG" == "latest" ]] || \
    die "Refusing to delete non-ephemeral image" 38

[[ "$(type -P skopeo)" ]] || \
    die "Cannot find skopeo binary" 39

reg_login

for name in "$BASE_IN" "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
do
    echo "Deleting '$REG_NS/$name:$IMG_TAG'"
    sudo skopeo delete "docker://$REG_NS/$name:$IMG_TAG" &
done

wait
