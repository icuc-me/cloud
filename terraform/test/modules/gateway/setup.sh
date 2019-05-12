#!/bin/bash

set -eo pipefail

SCRIPTFILEPATH="$0"
DATAFILEPATH="$1"

die(){
    RET="$1"
    [[ "$#" -ge "1" ]] || RET=120
    shift
    [[ "$RET" -ne "120" ]] || \
        echo "ERROR: die() expecting first parameter to be exit code, remaining parameters to be a message to display" > /proc/self/fd/2
    [[ "$RET" -eq "120" ]] || \
        echo "$@" > /proc/self/fd/2
    exit $RET
}

[[ -r "$DATAFILEPATH" ]] || \
    die 1 Expecting data filepath as first argument

DATA=$(cat "$DATAFILEPATH")
# Protect script and data from any prying eyes
rm -f "$DATAFILEPATH" "$SCRIPTFILEPATH"

eval "$DATA"

[[ -n "$PASSWD" ]] || \
    die 2 "Expecting \$PASSWD value in data to be non-empty"

echo "Setting password for $USER"
echo "$PASSWD" | sudo passwd --stdin $USER

if ((DEBUG))
then
    echo "Debugging Enabled"
    set -x
fi

echo "Enabling password logins"
sed -r -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/'

echo "Updating all packages"
sudo $(type -P yum || type -P dnf) update -y
