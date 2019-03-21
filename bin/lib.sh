
set -e

die() {
    echo -e "$1"
    exit $2
}

SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}
TF_DIR="$SRC_DIR/terraform"

eval "$(go env)"
export PATH="$GOPATH/bin:$PATH" >> $HOME/.bashrc
export $(go env | cut -d '=' -f 1)

cd $SRC_DIR
[[ "$CI" == "true" ]] && git fetch --tags &> /dev/null
VERSION="$(git describe --abbrev=6 HEAD || echo '0.0.0')"
VERSION_MAJ_MIN_REV="$(echo $VERSION | cut -d . -f 1-3 | cut -d - -f 1)"
VERSION_MAJ_MIN="$(echo $VERSION | cut -d . -f 1-2)"
VERSION_MAJ="$(echo $VERSION | cut -d . -f 1)"

# runtime
CONTAINER="${CONTAINER:-docker}"

if [[ "$CI" == "true" ]]
then
    if [[ -n "$CIRRUS_TAG" ]] && [[ "$CIRRUS_BRANCH" == "master" ]]
    then
        IMG_TAG="${VERSION_MAJ_MIN}"
    else
        IMG_TAG="${TEST_IMG_TAG}"
    fi
else
    IMG_TAG="${IMG_TAG:-$VERSION}"
fi

[[ "${IMG_TAG}" != "0.0.0" ]] || die "Invalid image tag 0.0.0, check build environment." 1

REG_NS="quay.io/r4z0r7o3"
IMG_SFX="cloud.icuc.me"
BA_TAG="--build-arg=TAG=${IMG_TAG}"

BASE_IN="base.${IMG_SFX}"
BASE_FQIN="${REG_NS}/${BASE_IN}:${IMG_TAG}"

PACKER_IN="packer.${IMG_SFX}"
PACKER_FQIN="${REG_NS}/${PACKER_IN}:${IMG_TAG}"

TFORM_IN="terraform.${IMG_SFX}"
TFORM_FQIN="${REG_NS}/${TFORM_IN}:${IMG_TAG}"

VALID_IN="validate.${IMG_SFX}"
VALID_FQIN="${REG_NS}/${VALID_IN}:${IMG_TAG}"

DEVEL_IN="devel.${IMG_SFX}"
DEVEL_FQIN="${REG_NS}/${DEVEL_IN}:${IMG_TAG}"
