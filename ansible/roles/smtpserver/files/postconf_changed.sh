#!/bin/bash

set -e

STRIP='s/^\s*(\S*)\s*$/\1/'

DEFAULTS=$(postconf -d)
postconf -n | while read ACTUAL
do
    KEY=$(echo "$ACTUAL" | cut -d "=" -f 1 | tr -d "[[:space:]]")
    echo "$DEFAULTS" | egrep -q "^$KEY =" || continue

    VALUE=$(echo "$ACTUAL" | cut -d "=" -f 2- | tr -s "[[:blank:]]" " " | sed -r -e "$STRIP")
    DEFVAL=$(echo "$DEFAULTS" | egrep "^$KEY =" | cut -d "=" -f 2- | tr -s "[[:blank:]]" " " | sed -r -e "$STRIP")
    if [[ "$VALUE" != "$DEFVAL" ]]
    then
	echo ""
        echo "# DEFAULT $KEY: $DEFVAL"
        echo "${KEY}: ${VALUE}"
    fi
done
