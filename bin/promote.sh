#!/bin/bash

set -e

source $(dirname $0)/lib.sh

MODKEY="NEEDS PER-ENV MODIFICATION"

case "$1" in
    test)
        SRC="test"
        DST="stage"
        ESB=""
        ;;
    stage)
        SRC="stage"
        DST="prod"
        ESB="--exclude=*-strongbox.yml"
        ;;
    prod)
        SRC="prod"
        DST="test"
        ESB="--exclude=*-strongbox.yml"
        ;;
    *) die "First parameter must be 'test', 'stage', or 'prod', got: '$1'." 1
esac

if [[ -d "$TF_DIR/$SRC/.terraform" ]] || [[ -d "$TF_DIR/$DST/.terraform" ]]
then
    die "Error, found .terraform directories in $SRC or $DST" 2
fi

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
    rm -rf "$TEMPDIR"/* "$TEMPDIR"/.??*
    make -C "$SRC_DIR/validate" .commits_clean
    rsync --archive --links \
        $ESB --exclude=*.auto.tfvars --exclude=.gitignore \
        "$TF_DIR/$SRC/" "$TEMPDIR"
    modfiles
    echo ""
    echo "$TEMPDIR"
    ls -la $TEMPDIR
    diff -Naur \
        --exclude=*-strongbox.yml --exclude=*.auto.tfvars --exclude=.gitignore \
        "$TF_DIR/$DST/" "$TEMPDIR/" | less
    read -N 1 -p "$TEMPDIR OKAY to proceed (y), re-edit/diff (r), or abort (n)? " YorNorR
    echo ""
    if [[ "$YorNorR" == "N" ]] || [[ "$YorNorR" == "n" ]]
    then
        exit 2
    fi
done

rsync --archive --links --delete \
   $ESB --exclude=*.auto.tfvars --exclude=.gitignore \
   "$TEMPDIR/"  "$TF_DIR/$DST"

cd "$TF_DIR"
git status
