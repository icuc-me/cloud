#!/bin/bash

set -e

source $(dirname $0)/lib.sh

mklockfile

cd $(dirname $0)/../

runuser -u safekeep -g safekeep -- \
    flock --close --timeout $LOCKTIMEOUT $LOCKFILE \
    /usr/bin/safekeep --list --sizes --noemail |& \
        egrep '(Server listing)|(current mirror)|(Fatal)(------)'
