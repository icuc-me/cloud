#!/bin/bash

set -e

source $(dirname $0)/lib.sh

show_env

expr "$CI" : "[Tt]rue" &> /dev/null || \
    die "Expecting \$CI to be 'true', not: $CI" 30

reg_login

for name in "$BASE_IN" "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
do
    echo "Pushing '$REG_NS/$name:$IMG_TAG'"
    $CONTAINER push "$REG_NS/$name:$IMG_TAG"
done
