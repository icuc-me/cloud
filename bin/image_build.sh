#!/bin/bash

set -e

source $(dirname $0)/lib.sh

docker_build() {
    REG="$1"
    NAME="$2"
    TAG="$3"
    shift 3
    IN="${NAME}:${TAG}"
    FQIN="${REG}/${IN}"
    [[ -n "$REG" ]] || die "${FUNCNAME[0]}() expects \$1 to be non-empty registry name" 3
    [[ -n "$NAME" ]] || die "${FUNCNAME[0]}() expects \$2 to be non-empty repository name" 3
    [[ -n "$TAG" ]] || die "${FUNCNAME[0]}() expects \$3 to be non-empty repository tag" 2

    cd "$SRC_DIR"
    CMD="sudo $CONTAINER build ${BA_TAG} -f dockerfiles/${NAME}.dockerfile --tag ${IN} ./"
    echo "$CMD"
    $CMD
    echo "Tagging ${IN} -> ${FQIN}"
    sudo $CONTAINER tag "${IN}" "${FQIN}"
    if [[ "$CI" == "true" ]] && [[ "$CIRRUS_BRANCH" == "master" ]]
    then
        sudo $CONTAINER tag "${IN}" "$REG/$NAME:${TEST_IMG_TAG:-YouFoundABug}"
    fi
    echo "########################################"
}

show_env

for name in "$BASE_IN" "$TOOLS_IN" "$RUN_IN"
do
    docker_build "$REG_NS" "$name" "$IMG_TAG"
done
