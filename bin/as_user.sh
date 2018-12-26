#!/bin/bash
set -ex
die() { echo -e "$2"; exit "$1"; }
[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'
groupadd -g "$AS_ID" "$AS_USER"
useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER"
set -x
rsync --quiet --stats --recursive --links \
    --safe-links --perms --sparse "--chown=$AS_ID:$AS_ID" \
    "/usr/src/" "/home/$AS_USER"
cd "/home/$AS_USER"
exec sudo --set-home --user "$AS_USER" --login --stdin /usr/bin/bash -i -l -c "$@"
