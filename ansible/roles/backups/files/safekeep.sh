#!/bin/sh

set -e

source $(dirname $0)/lib.sh

# Assume script executing from 'scripts' subdirectory
cd $(dirname $0)/../

mklockfile

if (($(date +%j) % 52))  # is multiple
then
    VERBOSE=${VERBOSE:-}
else
    VERBOSE=${VERBOSE:---quiet --noemail}
fi

runuser -u safekeep -g safekeep -- \
    flock --close --timeout $LOCKTIMEOUT $LOCKFILE \
    /usr/bin/safekeep --server $VERBOSE $@
