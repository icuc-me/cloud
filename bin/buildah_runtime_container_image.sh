#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"

# Allows packing multiple scripts into one file
_HOST="9d5a6ad6-25a0-471f-9f21-75e1be9c398e"
_LAYER_1="ee51f9f0-0301-4f3b-a3ab-aa3308820bac"
_LAYER_2="e93e002f-9443-466e-ab90-f78df5d5f7fa"
_LAYER_3="23cc6743-7e22-4401-8e68-4d4c3fc18849"
_LAYER_4="0e491b98-eb2b-4d69-a1d4-75bc487665c0"
_LAYER_5="a4028aa0-5e11-4ab7-989b-404b62b9749a"
MAGIC="${MAGIC:-$_HOST}"
INSTALL_RPMS="
    PyYAML
    ansible-2.7.5-1.el7
    python2-boto
    curl
    findutils
    git
    git
    google-cloud-sdk
    libselinux-python
    nmap-ncat
    python-pycurl
    python2-requests
    python-simplejson
    rsync
    rsync
    sshpass
    sudo
    unzip
    vim
    wget
"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip"

container=""
cleanup() {
    set +e
    [[ -z "$container" ]] || sudo buildah rm "$container"
}

build_layer() {
    FROM_NAME="$1"
    LAYER_NAME="$2"
    TAG_NAME="$3"
    XTRA_CONFIG="$4"

    echo "Building $LAYER_NAME"
    sudo podman rmi $LAYER_NAME:$TAG_NAME 2> /dev/null || true
    container=$(sudo buildah from \
                        --security-opt=label=disable \
                        --volume=$SRC_DIR:/usr/src:ro \
                        $FROM_NAME 2> /dev/null)
    trap cleanup EXIT
    sudo buildah config \
        "--label=MAGIC=$TAG_NAME" \
        "--label=VERSION=$VERSION" \
        "--label=PACKAGES=$INSTALL_RPMS" \
        "--env=MAGIC=$TAG_NAME" \
        "--env=VERSION=$VERSION" \
        "--env=PACKAGES=$INSTALL_RPMS" \
        $container 2> /dev/null
    set -x
    sudo buildah run $container -- /usr/src/$SCRIPT_SUBDIR/$SCRIPT_FILENAME
    [[ -z "$XTRA_CONFIG" ]] || sudo buildah config "$XTRA_CONFIG" $container
    sudo buildah commit --rm --format=docker $container "$LAYER_NAME:$TAG_NAME" 2> /dev/null
    set +x
    trap - EXIT
    unset FROM_NAME LAYER_NAME TAG_NAME XTRA_CONFIG
}

image_age() {
    # Avoid large pipeline for inline string conversion
    CREATED="$(sudo podman inspect --type image --format '{{.Created}}' $1 2> /dev/null || \
               echo '@0')"
    CREATED=$(echo "$CREATED" | cut -d ' ' -f 1-3)
    CREATED=$(date --date "$CREATED" +%s)
    NOW=$(date +%s)
    AGE=$[$NOW - $CREATED]
    echo "$AGE"
    unset CREATED NOW AGE
}

image_version() {
    echo $(sudo podman inspect --type image --format '{{.Labels.VERSION}}' "$1" 2> /dev/null || \
           echo '')
}

image_packages() {
    echo $(sudo podman inspect --type image --format '{{.Labels.PACKAGES}}' "$1" 2> /dev/null || \
           echo '')
}

rebuild_cache_layer(){
    LAYER_NUM="$1"
    LAYER_AGE="$2"
    LAYER_MAX_AGE="$3"
    LAYER_VER="$4"
    COMPARE_VER="$5"
    LAYER_PACKAGES="$6"
    CHANGED="$7"
    BUILD_CMD="$8"

    if ((CHANGED))
    then
        echo "Previous cache layer changed, rebuilding layer $LAYER_NUM"
        CHANGED=1
    elif [[ "$LAYER_PACKAGES" != "$INSTALL_RPMS" ]]
    then
        echo "Cached layer $LAYER_NUM package list ($LAYER_PACKAGES) unequal to current ($INSTALL_RPMS)"
        CHANGED=1
    elif [[ "$LAYER_VER" != "$COMPARE_VER" ]]
    then
        echo "Cached layer $LAYER_NUM version ($LAYER_VER) unequal to current ($COMPARE_VER)"
        CHANGED=1
    elif [[ "$LAYER_AGE" -gt "$LAYER_MAX_AGE" ]]
    then
        echo "Cached layer $LAYER_NUM age ($LAYER_AGE) greater than expected ($LAYER_MAX_AGE)."
        CHANGED=1
    else
        echo "Skipping build of cache layer $LAYER_NUM"
    fi

    if ((CHANGED)); then $BUILD_CMD; fi
}

if [[ "$MAGIC" == "$_HOST" ]]
then

    if ! type -P buildah &> /dev/null
    then
        die "The buildah command was not found on path" 1
    elif ! sudo buildah version &> /dev/null
    then
        die "Sudo access to buildah is required" 2
    elif ! type -P podman &> /dev/null
    then
        die "The podman command was not found on path" 3
    elif ! sudo podman version &> /dev/null
    then
        die "Sudo access to podman is required" 4
    elif [[ -z "$IMAGE_NAME" ]]
    then
        die "Error retrieving image name" 5
    fi

    LAYER_AGE="$(image_age layer_1:$_LAYER_1)"
    LAYER_MAX_AGE="$[60 * 60 * 24 * 28]"
    LAYER_MAJ_VER="$(image_version layer_1:$_LAYER_1 | cut -d . -f 1)"
    LAYER_PACKAGES="$INSTALL_RPMS"  # Don't care, installed in layer 2 (below)
    CHANGED=0
    rebuild_cache_layer 1 \
        "$LAYER_AGE" "$LAYER_MAX_AGE" \
        "$LAYER_MAJ_VER" "$VERSION_MAJ" \
        "$LAYER_PACKAGES" "$CHANGED" \
        "build_layer docker://centos:7 layer_1 $_LAYER_1"

    LAYER_AGE="$(image_age layer_2:$_LAYER_2)"
    LAYER_MAX_AGE="$[60 * 60 * 24 * 14]"
    LAYER_MAJ_MIN_VER="$(image_version layer_2:$_LAYER_2 | cut -d . -f 1-2)"
    LAYER_PACKAGES="$(image_packages layer_2:$_LAYER_2)"
    rebuild_cache_layer 2 \
        "$LAYER_AGE" "$LAYER_MAX_AGE" \
        "$LAYER_MAJ_MIN_VER" "$VERSION_MAJ_MIN" \
        "$LAYER_PACKAGES" "$CHANGED" \
        "build_layer layer_1:$_LAYER_1 layer_2 $_LAYER_2"

    LAYER_AGE="$(image_age layer_3:$_LAYER_3)"
    LAYER_MAX_AGE="$[60 * 60 * 24 * 7]"
    LAYER_MAJ_MIN_REV_VER="$(image_version layer_3:$_LAYER_3 | cut -d . -f 1-3 | cut -d - -f 1)"
    LAYER_PACKAGES="$(image_packages layer_3:$_LAYER_3)"
    rebuild_cache_layer 3 \
        "$LAYER_AGE" "$LAYER_MAX_AGE" \
        "$LAYER_MAJ_MIN_REV_VER" "$VERSION_MAJ_MIN_REV" \
        "$LAYER_PACKAGES" "$CHANGED" \
        "build_layer layer_2:$_LAYER_2 layer_3 $_LAYER_3"

    LAYER_AGE="$(image_age layer_4:$_LAYER_4)"
    LAYER_MAX_AGE="$[60 * 60 * 24 * 3]"
    LAYER_VER="$(image_version layer_4:$_LAYER_4)"
    LAYER_PACKAGES="$(image_packages layer_4:$_LAYER_4)"
    rebuild_cache_layer 4 \
        "$LAYER_AGE" "$LAYER_MAX_AGE" \
        "$LAYER_VER" "$VERSION" \
        "$LAYER_PACKAGES" "$CHANGED" \
        "build_layer layer_3:$_LAYER_3 layer_4 $_LAYER_4
        --entrypoint=[\"/root/bin/as_user.sh\"]"

    LAYER_AGE="$(image_age layer_5:$_LAYER_5)"
    LAYER_MAX_AGE="$[60 * 60 * 24 * 1]"
    LAYER_VER="$RANDOM"
    LAYER_PACKAGES="$(image_packages layer_5:$_LAYER_5)"
    rebuild_cache_layer 5 \
        "$LAYER_AGE" "$LAYER_MAX_AGE" \
        "$LAYER_VER" "$VERSION" \
        "$LAYER_PACKAGES" "$CHANGED" \
        "build_layer layer_4:$_LAYER_4 layer_5 $_LAYER_5"

    if ((CHANGED)) || ! sudo podman images $IMAGE_NAME &> /dev/null
    then
        sudo podman rm $IMAGE_NAME 2> /dev/null || true
        trap cleanup EXIT
        sudo podman tag layer_4:$_LAYER_4 $IMAGE_NAME
        trap - EXIT
    else
        echo "Skipping tag of layer 4"
    fi

    echo "Image ready for use: $IMAGE_NAME"

elif [[ "$MAGIC" == "$_LAYER_1" ]]
then
    yum update -y
    yum install -y epel-release
    cat << EOF > /etc/yum.repos.d/google-cloud-sdk.repo
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    yum clean all
    rm -rf /var/cache/yum
elif [[ "$MAGIC" == "$_LAYER_2" ]]
then
    yum install -y $INSTALL_RPMS
    yum clean all
    rm -rf /var/cache/yum
elif [[ "$MAGIC" == "$_LAYER_3" ]]
then
    cd /tmp
    echo "Installing Terraform"
    curl -o terraform.zip "$TERRAFORM_URL"
    unzip terraform.zip
    rm -f terraform.zip
    install -D -m 755 ./terraform /usr/local/bin/
    exit 0  # no-op
elif [[ "$MAGIC" == "$_LAYER_4" ]]
then
    echo "Installing entrypoint script"
    install -D -m 0755 /usr/src/$SCRIPT_SUBDIR/as_user.sh /root/bin/as_user.sh
elif [[ "$MAGIC" == "$_LAYER_5" ]]
then
    echo "Finalizing image"
    exit 0  # no-op
else
    die "You found a bug in the script! Current \$MAGIC=$MAGIC"
fi
