#!/bin/bash

# Development front-end for project
set -e

source "$(dirname $0)/lib.sh"

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
fi

set -x
sudo podman run -it --rm \
    --security-opt "label=disable" \
    --volume "$(host_home .vimrc)" \
    --volume "$(host_home .gitconfig)" \
    --volume "$SRC_DIR:/home/$USER/go/src/github.com/icuc-me/cloud/" \
    --workdir "/home/$USER/go/src/github.com/icuc-me/cloud/" \
    --env "AS_USER=$USER" \
    --env "AS_ID=$UID" \
    --env "DEVEL=1" \
    --env "PATH=/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/home/$USER/go/bin" \
    "$IMAGE_NAME" "bash"
