
set -e
set +x

die() {
    echo -e "$1"
    exit $2
}

SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}
TF_DIR="$SRC_DIR/terraform"

if type -P go &> /dev/null
then
    eval "$(go env)"
    export PATH="$GOPATH/bin:$PATH" >> $HOME/.bashrc
    export $(go env | cut -d '=' -f 1)
fi

cd $SRC_DIR
[[ "$CI" == "true" ]] && git fetch --tags &> /dev/null
VERSION="$(git describe --abbrev=6 HEAD || echo '0.0.0')"
VERSION_MAJ_MIN_REV="$(echo $VERSION | cut -d . -f 1-3 | cut -d - -f 1)"
VERSION_MAJ_MIN="$(echo $VERSION | cut -d . -f 1-2)"
VERSION_MAJ="$(echo $VERSION | cut -d . -f 1)"

# runtime
[[ "$CI" == "true" ]] && CONTAINER="${CONTAINER:-docker}"
CONTAINER="${CONTAINER:-podman}"

IMG_TAG="${IMG_TAG:-$VERSION}"
if [[ "$CI" == "true" ]]
then
    if [[ "$CIRRUS_BRANCH" == "master" ]]
    then
        IMG_TAG="${VERSION_MAJ_MIN_REV}"
    else
        IMG_TAG="${TEST_IMG_TAG}"
    fi
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

show_env(){
    ENVNAMES="$(env | egrep '^CIRRUS.+=' | cut -d '=' -f 1)
        $(go env | egrep '^.+=' | cut -d '=' -f 1)
        USER
        HOME
        PATH
        VERSION
        IMG_FQIN
        IMG_TAG
        REG_NS
        IMG_NAME
        TEST_IMG_TAG
        CI"
    for name in $ENVNAMES
    do
        local value="$(printenv $name)"
        [[ -z "$value" ]] || \
            echo "$name=$value"
    done
}

reg_login(){
    [[ -n "${REG_LOGIN}" ]] || \
        die "Expecting \$REG_LOGIN to be non-empty" 31

    [[ -n "${REG_PASSWD}" ]] || \
        die "Expecting \$REG_PASSWD to be non-empty" 32

    # Login, hide stdio, don't store in history
    echo "Logging in to remote repository"
    set +ex
    sudo $CONTAINER login -u="${REG_LOGIN}" -p="${REG_PASSWD}" quay.io
    history -c
    RET=$?
    set -e
    [[ "$RET" == 0 ]] || \
        die "Error logging in to registry, check \$REG_LOGIN and/or \$REG_PASSWD" 33
}
