
set -e

SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}
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
    mkdir -p "$SRC_DIR/terraform/$1/.terraform" 1> /dev/stderr
    echo "$SRC_DIR/terraform/$1/.terraform:/usr/src/terraform/$1/.terraform:rw"
}

host_home() {
    echo "$HOME/$1:/home/$USER/$1:ro"
}

check_usage() {
    if ! type -P podman &> /dev/null
    then
        die "The podman command was not found on path" 1
    elif ! sudo podman version &> /dev/null
    then
        die "Sudo access to podman is required" 2
    elif [[ -z "$IMAGE_NAME" ]]
    then
        die "Error retrieving image name" 3
    elif ! sudo podman images $IMAGE_NAME &> /dev/null
    then
        sudo podman pull $IMAGE_NAME || \
            $SCRIPT_DIRPATH/buildah_runtime_container_image.sh || \
            die "Error accessing image $IMAGE_NAME"
    elif ! echo "$SRC_DIR" egrep -q "/home/$USER/.+"
    then
        die "Expected source to exist as some subdirectory of /home/$USER" 4
    fi
}
