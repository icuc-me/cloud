#!/bin/bash

# Execution front-end for top-level Makefile runtime environment
set -e

source "$(dirname $0)/lib.sh"

check_usage

set -x
sudo podman run -it --rm \
    --security-opt "label=disable" \
    --volume "$SRC_DIR:/usr/src:ro" \
    --volume "$SRC_DIR/secrets:/usr/src/secrets:rw" \
    --volume "$(tf_data_dir test)" \
    --volume "$(tf_data_dir stage)" \
    --volume "$(tf_data_dir prod)" \
    --workdir "$SRC_DIR" \
    --env "SRC_DIR=$SRC_DIR" \
    --env "AS_USER=$USER" \
    --env "AS_ID=$UID" \
    "$IMAGE_NAME" "/usr/bin/make $@"
