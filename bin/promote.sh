#!/bin/bash

set -e

source $(dirname $0)/lib.sh

MODKEY="NEEDS PER-ENV MODIFICATION"

case "$1" in
    test)
        SRC="$TF_DIR/test"
        DST="$TF_DIR/stage"
        ROLLMOD=1
        ;;
    stage)
        SRC="$TF_DIR/stage"
        DST="$TF_DIR/prod"
        ROLLMOD=0
        ;;
    *) die "First parameter must be 'test' or 'stage', got: '$1'." 1
esac

make -C "$SRC_DIR/validate" .commits_clean

STAGEDIR="$(mktemp -p '' -d ${SCRIPT_FILENAME}_XXXX)"
trap "rm -rf $STAGEDIR" EXIT
cp --archive --target-directory "$STAGEDIR" "$SRC"

modfiles() {
    cd "$STAGEDIR"
    egrep --with-filename --line-number "--include=*.tf" --recursive "$MODKEY" ./ | sort | \
        while IFS=: read FILEPATH LINENUM TEXT
        do
            vim "$FILEPATH" "+$LINENUM" < /dev/tty > /dev/tty
        done
}

YorNorR="r"
while [[ "$YorNorR" == "R" ]] || [[ "$YorNorR" == "r" ]]
do
    modfiles
    read -N 1 -p "OKAY to proceed (y), re-edit (r), or abort (n)" YorNorR
    if [[ "$YorNorR" == "N" ]] || [[ "$YorNorR" == "n" ]]
    then
        exit 2
    fi
done

cd "$TF_DIR"

if ((ROLLMOD)) && [[ -d "$STAGEDIR/modules" ]]
then
    rm -rf modules
    cp --archive $STAGEDIR/modules "$TF_DIR"
    rm -rf "$STAGEDIR/modules"
fi

cp --archive --target-directory "$DST" $STAGEDIR/*

cd "$TF_DIR"
git status
