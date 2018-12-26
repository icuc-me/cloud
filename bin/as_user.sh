#!/bin/bash
set -e
die() { echo -e "$2"; exit "$1"; }
[[ -n "$AS_ID" ]] || die 2 'Expected \$AS_ID to be set.'
[[ -n "$AS_USER" ]] || die 3 'Expected \$AS_USER to be set.'
groupadd -g "$AS_ID" "$AS_USER"
useradd -g "$AS_ID" -u "$AS_ID" "$AS_USER"
set -x
echo "Creating a working copy of source"
rsync --stats --recursive --links \
    --safe-links --sparse \
    --executability --chmod=ug+w \
    "/usr/src/" "/home/$AS_USER"
cehown -R $AS_ID:$AS_ID "/home/$AS_USER"
set -x
exec sudo --set-home --user "$AS_USER" --preserve-env=PATH --stdin /usr/bin/bash -l -i -c "$@"
