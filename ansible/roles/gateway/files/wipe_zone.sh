#!/bin/bash

# Given the name of a zone, remove all sources, interfaces,
# services, ports, masquerading, and rich-rules.

set -eo pipefail

SCRIPT_NAME="$(basename $0)"
ZONE=$1
shift
CONTEXT="$@"
# Makes finding messages from this specific exectuion, easier to find
MESSAGE_ID=a82acc23087a4bda9f77b08149269e21

die() {
    echo "$2"
    exit $1
}

output_log() {
    echo "$@"
    logger --journald --skip-empty <<EOF
MESSAGE_ID=$MESSAGE_ID
CONTEXT=$CONTEXT
MESSAGE="$@"
PRIORITY=7
CODE_FILE=$SCRIPT_NAME
EOF
}

[[ -n "$1" ]] || die 1 "Expecting zone name as first argument"
[[ -n "$CONTEXT" ]] || die 2 "Expecting execution context string as arguments"

# Behave differently depending on how script was called
if [[ "$SCRIPT_NAME" == "wipe_zone_permanent.sh" ]]
then
    PERMANENT="--permanent"
elif [[ "$SCRIPT_NAME" == "wipe_zone.sh" ]]
then
    PERMANENT=""
else
    die 3 "Expecting to be called as wipe_zone.sh or wipe_zone_permanent.sh, not: $(basename $0)"
fi

[[ "$(firewall-cmd $PERMANENT --get-zones)" =~ "$ZONE" ]] || \
    die 3 "Invalid $PERMANENT zone '$ZONE'"

list_and_remove() {
    WHAT=$1
    LIST="--list-${WHAT}s"
    REMOVE="--remove-${WHAT}"

    # Ensure ITEMS is line-delimited
    if [[ "$REMOVE" =~ "rich-rule" ]]
    then
        ITEMS=$(firewall-cmd $PERMANENT --zone=$ZONE $LIST)
    else
        ITEMS=$(firewall-cmd $PERMANENT --zone=$ZONE $LIST | tr ' ' '\n')
    fi

    echo "$ITEMS" | while read item
    do
        [[ -n "$item" ]] || continue
        output_log "Clearing ${WHAT}s - Removing '$item' from $ZONE zone"
        firewall-cmd $PERMANENT --zone=$ZONE $REMOVE="$item"
    done
}

for what in source interface service port rich-rule
do
    list_and_remove $what
done

output_log "Clearing masquerading - Removing it from $ZONE zone"
firewall-cmd $PERMANENT --zone=$ZONE --remove-masquerade
