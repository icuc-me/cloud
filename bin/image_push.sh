#!/bin/bash

set -e

source $(dirname $0)/lib.sh

show_env

expr "$CI" : "[Tt]rue" &> /dev/null || \
    die "Expecting \$CI to be 'true', not: $CI" 30

reg_login

for name in "$BASE_IN" "$TOOLS_IN" "$RUN_IN"
do
    $CONTAINER push "$REG_NS/$name:$IMG_TAG"
    [[ "$IMG_TAG" == "$TEST_IMG_TAG" ]] || \
        sudo $CONTAINER push "$REG_NS/$name:$TEST_IMG_TAG"
done
