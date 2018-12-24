
set -e

SCRIPT_FILENAME=$(basename "$0")
SCRIPT_DIRPATH="$(dirname $0)"
SCRIPT_SUBDIR="$(basename $SCRIPT_DIRPATH)"
SRC_DIR=$(realpath "$SCRIPT_DIRPATH/../")
cd $SRC_DIR
# Don't fail building layer 1 b/c make not yet installed
IMAGE_NAME="$(make image_name 2> /dev/null || echo '')"
VERSION="$(make version 2> /dev/null || echo '')"

die() {
    echo -e "$1"
    exit $2
}
