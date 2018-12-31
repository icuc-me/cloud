
set -e

SCRIPT_FILENAME=$(basename "$0")
SCRIPT_DIRPATH="$(dirname $0)"
SCRIPT_SUBDIR="$(basename $SCRIPT_DIRPATH)"
SRC_DIR=$(realpath "$SCRIPT_DIRPATH/../")
cd $SRC_DIR
# Don't fail building layer 1 b/c make not yet installed
IMAGE_NAME="$(make image_name 2> /dev/null || echo '')"
VERSION="$(make version 2> /dev/null || echo '')"
VERSION_MAJ_MIN_REV="$(echo $VERSION | cut -d . -f 1-3 | cut -d - -f 1)"
VERSION_MAJ_MIN="$(echo $VERSION | cut -d . -f 1-2)"
VERSION_MAJ="$(echo $VERSION | cut -d . -f 1)"

die() {
    echo -e "$1"
    exit $2
}

tf_data_dir() {
    echo "$SRC_DIR/terraform/$1/.terraform:/usr/src/terraform/$1/.terraform:rw"
}

