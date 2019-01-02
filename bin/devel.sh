#!/bin/bash

# Development front-end for project
set -e

source "$(dirname $0)/lib.sh"

check_usage

set -x
sudo podman run -it --rm \
    --security-opt "label=disable" \
    --volume "$(host_home .vimrc)" \
    --volume "$(host_home .gitconfig)" \
    --volume "$SRC_DIR:$SRC_DIR" \
    --workdir "$SRC_DIR" \
    --env "SRC_DIR=$SRC_DIR" \
    --env "AS_USER=$USER" \
    --env "AS_ID=$UID" \
    "$IMAGE_NAME"
