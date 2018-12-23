#!/bin/bash

set -e

SCRIPT_FILENAME=$(basename "$0")
SCRIPT_SUBDIR=$(basename "$(dirname $0)")
SRC_DIR=$(realpath "$(dirname $0)/../")
IMAGE_NAME="$1"
# Allows packing multiple scripts into one file
_HOST="9d5a6ad6-25a0-471f-9f21-75e1be9c398e"
_LAYER_1="ee51f9f0-0301-4f3b-a3ab-aa3308820bac"
MAGIC="${MAGIC:-$_HOST}"

INSTALL_RPMS="ansible-2.7.5-1.el7"

die() {
    echo -e "$1"
    exit $2
}

container=""
cleanup() {
    set +e
    [[ -z "$container" ]] || sudo buildah rm "$container"
}

if [[ "$MAGIC" == "$_HOST" ]]
then

    if ! type -P buildah &> /dev/null
    then
        die "The buildah command was not found on path" 1
    elif ! sudo buildah version &> /dev/null
    then
        die "Sudo access to buildah is required" 2
    elif [[ -z "$IMAGE_NAME" ]]
    then
        die "First parameter must be the name of the output container image" 3
    fi

    trap cleanup EXIT

    # TODO: Only build layer 1 if: doesn't exist or more than one-week old
    # TODO: Support more than one layer
    set -x
    container=$(sudo buildah from \
                        --pull-always \
                        --security-opt=label=disable \
                        --volume=$SRC_DIR:/usr/src:ro \
                        docker://centos:7)
    sudo buildah config \
        "--label=MAGIC=$_LAYER_1" \
        "--env=MAGIC=$_LAYER_1" \
        $container
    sudo buildah run $container -- /usr/src/$SCRIPT_SUBDIR/$SCRIPT_FILENAME
    sudo buildah commit --format=docker $container "$IMAGE_NAME"

elif [[ "$MAGIC" == "$_LAYER_1" ]]
then
    yum update -y
    yum install -y epel-release
    yum install -y $INSTALL_RPMS
    yum clean all
    rm -rf /var/cache/yum
else
    die "You found a bug in the script! Current \$MAGIC=$MAGIC"
fi
