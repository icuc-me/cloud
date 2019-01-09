
set -e

SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}
cd $SRC_DIR
# Don't fail building layer 1 b/c make not yet installed
IMAGE_NAME="$(make image_name 2> /dev/null || echo '')"
VERSION="$(make version | egrep -m 1 '^\d+\.\d+\.\d+(-.+)?' || echo '')"
VERSION_MAJ_MIN_REV="$(echo $VERSION | cut -d . -f 1-3 | cut -d - -f 1)"
VERSION_MAJ_MIN="$(echo $VERSION | cut -d . -f 1-2)"
VERSION_MAJ="$(echo $VERSION | cut -d . -f 1)"

die() {
    echo -e "$1"
    exit $2
}
