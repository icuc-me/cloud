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
    CMD="$CONTAINER build ${BA_TAG} -f dockerfiles/${NAME}.dockerfile --tag ${IN} ${XTRA:-} ./"
    echo "$CMD"
    $CMD
    echo "Tagging ${IN} -> ${FQIN}"
    $CONTAINER tag "${IN}" "${FQIN}"
    echo "########################################"
}

unset XTRA
[[ "$CI" != "true" ]] || XTRA="--no-cache"
docker_build "$REG_NS" "$BASE_IN" "$IMG_TAG" $XTRA

unset XTRA
for name in "$PACKER_IN" "$TFORM_IN" "$VALID_IN" "$DEVEL_IN"
do
    docker_build "$REG_NS" "$name" "$IMG_TAG"
done
