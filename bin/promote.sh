#!/bin/bash

set -e

source $(dirname $0)/lib.sh

MODKEY="NEEDS PER-ENV MODIFICATION"
EXCLUDE="--exclude=*-strongbox.yml --exclude=*.auto.tfvars --exclude=.gitignore"

case "$1" in
    test)
        SRC="test"
        DST="stage"
        ;;
    stage)
        SRC="stage"
        DST="prod"
        ;;
    prod)
        SRC="prod"
        DST="test"
        ;;
    *) die "First parameter must be 'test', 'stage', or 'prod', got: '$1'." 1
esac

TEMPDIR="$(mktemp -p '' -d ${SCRIPT_FILENAME}_XXXX)"
trap "rm -rf $TEMPDIR" EXIT

modfiles() {
    cd "$TEMPDIR"
    egrep --with-filename --line-number "--include=*.tf" --recursive "$MODKEY" ./ | sort | \
        while IFS=: read FILEPATH LINENUM TEXT
        do
            vim "$FILEPATH" "+$LINENUM" < /dev/tty > /dev/tty
        done
}

YorNorR="r"
while [[ "$YorNorR" == "R" ]] || [[ "$YorNorR" == "r" ]]
do
    make -C "$SRC_DIR/validate" .commits_clean
    rsync --archive --links $EXCLUDE "$TF_DIR/$SRC/" "$TEMPDIR"
    modfiles
    echo ""
    echo "$TMPDIR"
    ls -la $TMPDIR
    read -N 1 -p "$TMPDIR OKAY to proceed (y), re-edit (r), or abort (n)? " YorNorR
    echo ""
    if [[ "$YorNorR" == "N" ]] || [[ "$YorNorR" == "n" ]]
    then
        exit 2
    fi
done

rsync --archive --links --delete $EXCLUDE "$TEMPDIR/"  "$TF_DIR/$DST"

cd "$TF_DIR"
git status
