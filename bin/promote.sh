#!/bin/bash

set -e

source $(dirname $0)/lib.sh

MODKEY="NEEDS PER-ENV MODIFICATION"
EXCLUDE='--exclude="*-strongbox.yml" --exclude="common_provider.tf" --exclude="common_*_variables.tf" --exclude=".gitignore"'

case "$1" in
    test)
        SRC="test"
        DST="stage"
        ROLLMOD=1
        ;;
    stage)
        SRC="stage"
        DST="prod"
        ROLLMOD=0
        ;;
    *) die "First parameter must be 'test' or 'stage', got: '$1'." 1
esac

make -C "$SRC_DIR/validate" .commits_clean

TEMPDIR="$(mktemp -p '' -d ${SCRIPT_FILENAME}_XXXX)"
trap "rm -rf $TEMPDIR" EXIT
rsync --archive --links $EXCLUDE "$TF_DIR/$SRC" "$TEMPDIR/"

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
    modfiles
    read -N 1 -p "OKAY to proceed (y), re-edit (r), or abort (n)" YorNorR
    echo ""
    if [[ "$YorNorR" == "N" ]] || [[ "$YorNorR" == "n" ]]
    then
        exit 2
    fi
done

rsync --progress --archive --links --delete $EXCLUDE "$TEMPDIR/$SRC/"  "$TF_DIR/$DST/"

if ((ROLLMOD)) && [[ -d "$TF_DIR/$DST/modules" ]]
then
    rsync --progress --archive --links --delete "$TF_DIR/$DST/modules" "$TF_DIR"
    rm -rf "$TF_DIR/$DST/modules"
    ln -sf "../modules" "$TF_DIR/$DST/modules"
fi

cd "$TF_DIR"
git status
