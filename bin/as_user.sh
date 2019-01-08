#!/bin/bash

set -e

die() {
    echo -e "$2"; exit "$1"
}

lnrwsrc() {
    rm -rf "$SRC_DIR/$1"
    mkdir -p $(dirname "$SRC_DIR/$1")
    ln -s "/usr/src/$1" "$SRC_DIR/$1"
}

[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'
[[ -n "$SRC_DIR" ]] || die 4 'Expected \$SRC_DIR to be set.'

cd "$SRC_DIR"

if ! id "$AS_USER" &> /dev/null
then
    groupadd -g "$AS_ID" "$AS_USER"
    useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER" --no-create-home  # assumed volume mount
    install -o "$AS_ID" -g "$AS_ID" /etc/skel/.??* /home/$AS_USER
fi

RSYNC_CMD="rsync --stats --recursive --links \
           --safe-links --sparse --checksum \
           --executability --chmod=ug+w \
           --exclude=secrets \
           --exclude=.terraform \
           --chown=$AS_ID:$AS_ID"

echo "Recovering cached GOPATH contents"
$RSYNC_CMD "/var/cache/go" "/home/$AS_USER"

if [[ -r "/usr/src/secrets/README.md" ]]
then
    echo "Creating working copy of read-only source"
    $RSYNC_CMD "/usr/src/" "$SRC_DIR"
    echo "Linking to host secrets and terraform cache"
    lnrwsrc secrets
    lnrwsrc terraform/test/.terraform
    lnrwsrc terraform/stage/.terraform
    lnrwsrc terraform/prod/.terraform
    SHELLCMD="$@"
else
    SHELLCMD="/usr/bin/bash --login -i"
fi

# rsync --chown doesn't affect directories somehow(?)
echo "Correcting permissions and configuring .bash_profile"
chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
install -o "$AS_ID" -g "$AS_ID" -m 0664 "$SRC_DIR/.bash_profile" "/home/$AS_USER/"
echo "export SRC_DIR=\"$SRC_DIR\"" >> "/home/$AS_USER/.bash_profile"
echo "export PATH=\"\$PATH:$SRC_DIR/bin\"" >> "/home/$AS_USER/.bash_profile"

echo "Entering prepared environment"
set -x
exec sudo --set-home --user "$AS_USER" --login --stdin /usr/bin/bash -l -i -c "cd $SRC_DIR && $SHELLCMD"
