#!/bin/bash

# Development front-end for project
set -e

source "$(dirname $0)/lib.sh"

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

host_ro() {
    echo "$HOME/$1:/home/$USER/$1:ro"
}


check_usage

if [[ "$(basename $0)" == "devel.sh" ]]
then
    set -x
    sudo podman run -it --rm \
       --security-opt "label=disable" \
       --volume "$(host_ro .vimrc)" \
       --volume "$(host_ro .gitconfig)" \
       --volume "$SRC_DIR:$SRC_DIR" \
       --workdir "$SRC_DIR" \
       --env "SRC_DIR=$SRC_DIR" \
       --env "AS_USER=$USER" \
       --env "AS_ID=$UID" \
       "$IMAGE_NAME" \
    "/usr/bin/bash --login -i"
else  # make.sh
    set -x
    sudo podman run -it --rm \
       --security-opt "label=disable" \
       --volume "$(host_ro .vimrc)" \
       --volume "$(host_ro .gitconfig)" \
       --volume "$SRC_DIR:$SRC_DIR" \
       --workdir "$SRC_DIR" \
       --env "SRC_DIR=$SRC_DIR" \
       --env "AS_USER=$USER" \
       --env "AS_ID=$UID" \
       "$IMAGE_NAME" \
    "/usr/bin/make $@"
fi
