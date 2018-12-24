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
fi

sudo podman run -it --rm \
    --security-opt=label=disable \
    --volume $PWD:/usr/src:ro \
    --workdir /usr/src \
    $IMAGE_NAME make $@
