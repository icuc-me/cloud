#!/bin/bash

set -e

source $(dirname $0)/lib.sh

show_env

[[ "$CI" == "true" ]] || \
    die "Expecting $CI to be 'true', not: $CI" 30

[[ -n "${REG_LOGIN}" ]] || \
    die "Expecting \$REG_LOGIN to be non-empty" 31

[[ -n "${REG_PASSWD}" ]] || \
    die "Expecting \$REG_PASSWD to be non-empty" 32

# Login, hide stdio, don't store in history
set +e
sudo $CONTAINER login -u="${REG_LOGIN}" -p="${REG_PASSWD}" quay.io &> /dev/null
history -c
RET=$?
set -e
[[ "$RET" == 0 ]] || \
    die "Error logging in to registry, check \$REG_LOGIN and/or \$REG_PASSWD" 33


for name in "$BASE_IN" "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
do
    echo "Pushing '$REG_NS/$name:$IMG_TAG'"
    $CONTAINER push "$REG_NS/$name:$IMG_TAG"

    if [[ "$CIRRUS_BRANCH" == "master" ]] && [[ "$1" == "tag-latest" ]]
    then
        echo "Tagging '$REG_NS/$name:latest'"
        sudo $CONTAINER tag "$REG_NS/$name:$IMG_TAG" "$REG_NS/$name:latest"
        sudo $CONTAINER push "$REG_NS/$name:latest"
    fi
done
