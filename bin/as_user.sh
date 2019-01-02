#!/bin/bash

set -e

die() {
    echo -e "$2"; exit "$1"
}

lnrwsrc() {
    rm -rf "/home/$AS_USER/$1"
    mkdir -p $(dirname "/home/$AS_USER/$1")
    ln -s "/usr/src/$1" "/home/$AS_USER/$1"
}

[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'

if ! id "$AS_USER" &> /dev/null
then
    groupadd -g "$AS_ID" "$AS_USER"
    useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER" --no-create-home  # fails if volume mount
    mkdir -p "/home/$AS_USER"  # does not fail if volume mount
    chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
    install -o "$AS_ID" -g "$AS_ID" /etc/skel/.??* /home/$AS_USER
fi

RSYNC_CMD="rsync --stats --recursive --links \
           --safe-links --sparse --checksum \
           --executability --chmod=ug+w \
           --exclude=secrets \
           --exclude=.terraform \
           --chown=$AS_ID:$AS_ID"

if [[ -z "$DEVEL" ]]
then
    echo "Creating a working copy of source"
    $RSYNC_CMD "/usr/src/" "/home/$AS_USER"
    # rsync --chown doesn't affect directories somehow(?)
    chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
    lnrwsrc secrets
    lnrwsrc terraform/test/.terraform
    lnrwsrc terraform/stage/.terraform
    lnrwsrc terraform/prod/.terraform
    SHELLCMD="cd /home/$AS_USER && $@"
else
    echo "Recovering cached go packages"
    $RSYNC_CMD "/var/cache/go" "/home/$AS_USER"
    chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
    install -o "$AS_ID" -g "$AS_ID" "$PWD/.bash_profile" "/home/$AS_USER/"
    SHELLCMD="cd $PWD && /usr/bin/bash --login -i"
fi

echo "Entering prepared environment"
set -x
exec sudo --set-home --user "$AS_USER" --login --stdin /usr/bin/bash -l -i -c "$SHELLCMD"
