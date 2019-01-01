#!/bin/bash

# Execution front-end for top-level Makefile runtime environment

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
    --volume "$SRC_DIR:/usr/src:ro" \
    --volume "$SRC_DIR/secrets:/usr/src/secrets:rw" \
    --volume "$(tf_data_dir test)" \
    --volume "$(tf_data_dir stage)" \
    --volume "$(tf_data_dir prod)" \
    --workdir "/usr/src" \
    --env "AS_USER=$USER" \
    --env "AS_ID=$UID" \
    "$IMAGE_NAME" "/usr/bin/make $@"
