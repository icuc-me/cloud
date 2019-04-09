#!/bin/bash

# Development front-end, intended to be called by humans, not automation.
set -e

source "$(dirname $0)/lib.sh"

check_usage() {
    if ! type -P $CONTAINER &> /dev/null
    then
        die "The $CONTAINER command was not found on path" 1
    elif ! sudo podman version &> /dev/null
    then
        die "Sudo access to $CONTAINER is required" 2
    elif [[ -z "$DEVEL_FQIN" ]]
    then
        die "Error image name is empty" 3
    elif ! sudo $CONTAINER images $DEVEL_FQIN &> /dev/null
    then
        if ! sudo $CONTAINER pull docker://$DEVEL_FQIN
        then
            $SCRIPT_DIRPATH/image_build.sh || \
                die "Error pulling or building image $DEVEL_FQIN"
        fi
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
    sudo $CONTAINER run -it --rm \
       --security-opt "label=disable" \
       --volume "$(host_ro .vimrc)" \
       --volume "$(host_ro .gitconfig)" \
       --volume "$SRC_DIR:$SRC_DIR" \
       --workdir "$SRC_DIR" \
       --env "SRC_DIR=$SRC_DIR" \
       --env "AS_USER=$USER" \
       --env "AS_ID=$UID" \
       "$DEVEL_FQIN" \
    "/usr/bin/bash --login -i"
else  # make.sh
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
       "$DEVEL_FQIN" \
    "/usr/bin/make $@"
fi
