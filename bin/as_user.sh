#!/bin/bash

set -e

die() {
    echo -e "$2"; exit "$1"
}

lnrwsrc() {
    rm -rf "/home/$AS_USER/$1"
    mkdir -p "/home/$AS_USER/$1"
    ln -s "/usr/src/$1" "/home/$AS_USER/$1"
}

[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'

if ! id "$AS_USER" &> /dev/null
then
    groupadd -g "$AS_ID" "$AS_USER"
    useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER" --no-create-home
    chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
    install -o "$AS_ID" -g "$AS_ID" /etc/skel/.??* /home/$AS_USER
fi

if [[ -z "$DEVEL" ]]
then
    echo "Creating a working copy of source"
    rsync --stats --recursive --links \
        --safe-links --sparse \
        --executability --chmod=ug+w \
        --exclude=secrets \
        "/usr/src/" "/home/$AS_USER"
    lnrwsrc secrets
    lnrwsrc terraform/test/.terraform
    lnrwsrc terraform/stage/.terraform
    lnrwsrc terraform/prod/.terraform
    SHELLCMD="cd /home/$AS_USER && $@"
else
    rsync --stats --recursive --links \
        --safe-links --sparse \
        --executability --chmod=ug+w \
        --exclude=secrets \
        "/var/cache/go" "/home/$AS_USER"
    chown -R $AS_ID:$AS_ID "/home/$AS_USER" &> /dev/null || true  # ignore any ro errors
    SHELLCMD="cd $PWD && /usr/bin/bash --rcfile /home/$AS_USER/.bash_profile --login -i"
fi

set -x
exec sudo --set-home --user "$AS_USER" --login --stdin /usr/bin/bash -l -i -c "$SHELLCMD"
