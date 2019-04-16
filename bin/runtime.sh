#!/bin/bash

# Development front-end, intended to be called by humans, not automation.
set -e

IMG_TAG="${IMG_TAG:-latest}"

source "$(dirname $0)/lib.sh"

check_usage() {
    if ! type -P $CONTAINER &> /dev/null
    then
        die "The $CONTAINER command was not found on path" 1
    elif ! sudo $CONTAINER version &> /dev/null
    then
        die "Sudo access to $CONTAINER is required" 2
    elif ! echo "$SRC_DIR" egrep -q "/home/$USER/.+"
    then
        die "Expected source to exist as some subdirectory of /home/$USER" 4
    elif ! sudo $CONTAINER image "$RUN_FQIN" &> /dev/null
    then
        if ! sudo $CONTAINER pull "$RUN_FQIN"
        then
            $SRC_DIR/bin/image_build.sh
        fi
    fi
}

host_ro() {
    echo "$HOME/$1:/home/$USER/$1:ro"
}


check_usage

if [[ "$(basename $0)" == "runtime.sh" ]]
then
    set -x
    sudo $CONTAINER run -it --rm \
       --security-opt "label=disable" \
       --volume "$(host_ro .vimrc)" \
       --volume "$(host_ro .gitconfig)" \
       --volume "$SRC_DIR:$SRC_DIR" \
       --workdir "$SRC_DIR" \
       --env "SRC_DIR=$SRC_DIR" \
       --env "AS_USER=$USER" \
       --env "AS_ID=$UID" \
       "$RUN_FQIN" \
    "/usr/bin/bash --login -i"
elif [[ "$(basename $0)" == "make.sh" ]]
then
    set -x
    sudo $CONTAINER run -i --rm \
       --security-opt "label=disable" \
       --volume "$(host_ro .vimrc)" \
       --volume "$(host_ro .gitconfig)" \
       --volume "$SRC_DIR:$SRC_DIR" \
       --workdir "$SRC_DIR" \
       --env "SRC_DIR=$SRC_DIR" \
       --env "AS_USER=$USER" \
       --env "AS_ID=$UID" \
       "$RUN_FQIN" \
    "/usr/bin/make $@"
fi
