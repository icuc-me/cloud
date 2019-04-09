#!/bin/bash

set -e

source $(dirname $0)/lib.sh

if [[ "$CI" == "true" ]]
then
    [[ -n "${REG_LOGIN}" ]] && [[ -n "${REG_PASSWD}" ]] && $CONTAINER login -u="${REG_LOGIN}" -p="${REG_PASSWD}" quay.io &> /dev/null
    history -c

    for name in "$BASE_IN" "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
    do
        $CONTAINER push "$REG_NS/$name:$IMG_TAG"
        [[ "$CIRRUS_BRANCH" != "master" ]] || \
            $CONTAINER push "$REG_NS/$name:latest"
    done
else
    die "Expected \$CI: 'true', got: '$CI'"
fi
