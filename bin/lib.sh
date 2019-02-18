
set -e

SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}
cd $SRC_DIR
# Don't fail building layer 1 b/c make not yet installed
IMAGE_NAME="$(make image_name 2> /dev/null || echo '')"
IMAGE_TAG=$(echo "$IMAGE_NAME" | cut -d : -f 2 || echo '')
IMAGE_BASE=$(echo "$IMAGE_NAME" | cut -d : -f 1 || echo '')
VERSION="$(make version | egrep -a -m 1 '^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+(-.+)?' || echo '')"
VERSION_MAJ_MIN_REV="$(echo $VERSION | cut -d . -f 1-3 | cut -d - -f 1)"
VERSION_MAJ_MIN="$(echo $VERSION | cut -d . -f 1-2)"
VERSION_MAJ="$(echo $VERSION | cut -d . -f 1)"
# Container layer magic values
_HOST="9d5a6ad6"
_LAYER_1="ee51f9f0"  # repos + updates
_LAYER_2="93e0e02f"  # packaged deps
_LAYER_3="23cc6743"  # unpackaged deps
_LAYER_4="0e491b98"  # configuration
_LAYER_5="a4028aa0"  # entrypoint

die() {
    echo -e "$1"
    exit $2
}
