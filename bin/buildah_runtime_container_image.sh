#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"

# Allows packing multiple scripts into one file
_HOST="9d5a6ad6-25a0-471f-9f21-75e1be9c398e"
_LAYER_1="ee51f9f0-0301-4f3b-a3ab-aa3308820bac"
_LAYER_2="e93e002f-9443-466e-ab90-f78df5d5f7fa"
_LAYER_3="23cc6743-7e22-4401-8e68-4d4c3fc18849"
_LAYER_4="0e491b98-eb2b-4d69-a1d4-75bc487665c0"
MAGIC="${MAGIC:-$_HOST}"
INSTALL_RPMS="ansible-2.7.5-1.el7 rsync git vim unzip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip"

container=""
cleanup() {
    set +e
    [[ -z "$container" ]] || sudo buildah rm "$container"
}

build_layer() {
    FROM_NAME="$1"
    LAYER_NAME="$2"
    XTRA_CONFIG="$3"

    sudo podman rmi $LAYER_NAME 2> /dev/null || true
    set -x
    container=$(sudo buildah from \
                        --security-opt=label=disable \
                        --volume=$SRC_DIR:/usr/src:ro \
                        $FROM_NAME)
    trap cleanup EXIT
    sudo buildah config \
        "--label=MAGIC=$LAYER_NAME" \
        "--label=VERSION=$VERSION" \
        "--env=MAGIC=$LAYER_NAME" \
        "--env=VERSION=$VERSION" \
        $container
    sudo buildah run $container -- /usr/src/$SCRIPT_SUBDIR/$SCRIPT_FILENAME
    [[ -z "$XTRA_CONFIG" ]] || sudo buildah config $XTRA_CONFIG $container
    sudo buildah commit --rm --format=docker $container "$LAYER_NAME:$VERSION"
    trap - EXIT
    set +x
    unset FROM_NAME LAYER_NAME XTRA_CONFIG
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

    CHANGED=0
    if [[ "$(image_age $_LAYER_1:$VERSION)" -ge "$[60 * 60 * 24 * 7]" ]] || \
       [[ "$(image_packages $_LAYER_1:$VERSION)" != "$INSTALL_RPMS" ]]
    then
        build_layer docker://centos:7 $_LAYER_1 "--label=PACKAGES=$INSTALL_RPMS"
        CHANGED=1
    else
        echo "Skipping build of layer 1"
    fi

    if ((CHANGED)) || \
       [[ $(image_version $_LAYER_1:$VERSION) != $(image_version $_LAYER_2:$VERSION) ]] || \
       [[ "$(image_packages $_LAYER_1:$VERSION)" != "$INSTALL_RPMS" ]]
    then
        build_layer $_LAYER_1:$VERSION $_LAYER_2
        CHANGED=1
    else
        echo "Skipping build of layer 2"
    fi

    if ((CHANGED)) || \
       [[ $(image_version $_LAYER_2:$VERSION) != $(image_version $_LAYER_3:$VERSION) ]] || \
       [[ "$(image_packages $_LAYER_2:$VERSION)" != "$INSTALL_RPMS" ]]
    then
        build_layer $_LAYER_2:$VERSION $_LAYER_3
        CHANGED=1
    else
        echo "Skipping build of layer 3"
    fi

    if ((CHANGED)) || \
       [[ $(image_version $_LAYER_3:$VERSION) != $(image_version $_LAYER_4:$VERSION) ]] || \
       [[ "$(image_packages $_LAYER_3:$VERSION)" != "$INSTALL_RPMS" ]]
    then
        build_layer $_LAYER_3:$VERSION $_LAYER_4
            "--entrypoint=/root/bin/as_user.sh"
        CHANGED=1
    else
        echo "Skipping build of layer 4"
    fi

    if ((CHANGED)) || ! sudo podman images $IMAGE_NAME &> /dev/null
    then
        sudo podman rm $IMAGE_NAME 2> /dev/null || true
        sudo podman tag $_LAYER_4:$VERSION $IMAGE_NAME
    else
        echo "Skipping tag of layer 4"
    fi


elif [[ "$MAGIC" == "$_LAYER_1" ]]
then
    yum update -y
    yum install -y epel-release
    yum install -y $INSTALL_RPMS
    yum clean all
    rm -rf /var/cache/yum
elif [[ "$MAGIC" == "$_LAYER_2" ]]
then
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
    yum install -y google-cloud-sdk
    cd /tmp
    curl -o terraform.zip "$TERRAFORM_URL"
    unzip terraform.zip
    rm -f terraform.zip
    install -D -m 755 ./terraform /usr/local/bin/
    yum clean all
    rm -rf /var/cache/yum
elif [[ "$MAGIC" == "$_LAYER_3" ]]
then
    mkdir -p /root/bin
    cat << "EOF" > /root/bin/as_user.sh
#!/bin/bash
set -e
die() { echo -e "$2"; exit $1 }
[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'
groupadd -g "$AS_ID" "$AS_USER"
useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER"
set -x
rsync --quiet --stats --recursive --links --safe-links --perms --sparse --chown=$AS_ID:$AS_ID \
    "/usr/src/" "/home/$AS_USER"
cd /home/$AS_USER
exec sudo --set-home --user "$AS_USER" --login --stdin /usr/bin/bash -i -l -c "$@"
EOF
    chmod +x /root/bin/as_user.sh
elif [[ "$MAGIC" == "$_LAYER_4" ]]
then
    exit 0  # no-op
else
    die "You found a bug in the script! Current \$MAGIC=$MAGIC"
fi
