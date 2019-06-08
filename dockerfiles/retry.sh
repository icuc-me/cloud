#!/bin/bash

TIMEOUT=$1
ATTEMPTS=$2
DELAY=$3
shift 3
CMD="$@"

die() {
    echo "************************************************"
    echo ">>>>> ${2:-FATAL ERROR (but no message given!)}"
    echo "************************************************"
    exit ${1:-1}
}

type -P tee &> /dev/null || \
    die 1 "Cannot find required tee binary"
type -P timeout &> /dev/null || \
    die 2 "Cannot find required timeout binary"
[[ "$TIMEOUT" -gt "0" ]] || \
    die 3 "Must specify timeout greater than 0 seconds, as first parameter"
[[ "$ATTEMPTS" -gt "0" ]] || \
    die 4 "Must specify attempts greater than 0, as second parameter"
[[ "$DELAY" -gt "0" ]] || \
    die 5 "Must specify delay greater than 0 seconds, as third parameter"
[[ -n "$CMD" ]] || \
    die 6 "Must specify a command and arguments as final parameters"

STDOUTERR=$(mktemp -p '' $(basename $0)_XXXXX)
trap "rm -f $STDOUTERR" EXIT

echo "Retrying $ATTEMPTS times with a $DELAY delay, and $TIMEOUT timeout for command: '$CMD'" |& tee -a "$STDOUTERR"
for (( COUNT=1 ; COUNT <= $ATTEMPTS ; COUNT++ ))
do
    echo "##### (attempt #$COUNT)"
    if timeout --foreground --kill-after=1 $TIMEOUT $CMD &>> "$STDOUTERR"
    then
        echo "##### (success after #$COUNT attempts)"
        break
    else
        echo "##### (failed with exit: $?)" &>> "$STDOUTERR"
        sleep $DELAY
    fi
done

if (( COUNT > $ATTEMPTS ))
then
    echo -e "\n\n##### (exceeded $ATTEMPTS attempts); Complete output follows:"
    cat "$STDOUTERR"
    exit 125
fi
