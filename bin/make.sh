#!/bin/bash

# Execution front-end for top-level Makefile runtime environment

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
    --security-opt=label=disable \
    --volume $PWD:/usr/src:ro \
    --volume $PWD/secrets:/usr/src/secrets:rw \
    --workdir /usr/src \
    --env AS_USER=$USER \
    --env AS_ID=$UID \
    --env PATH="/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin" \
    $IMAGE_NAME "/usr/bin/make $@"
