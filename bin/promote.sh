#!/bin/bash

set -e

source $(dirname $0)/lib.sh

MODKEY="NEEDS PER-ENV MODIFICATION"
EXCLUDE="--exclude=*-strongbox.yml --exclude=*.auto.tfvars --exclude=.gitignore"

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
rsync --archive --links $EXCLUDE "$TF_DIR/$SRC/" "$TEMPDIR"

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
    echo ""
    ls -la $TMPDIR
    read -N 1 -p "$TMPDIR OKAY to proceed (y), re-edit (r), or abort (n)? " YorNorR
    echo ""
    if [[ "$YorNorR" == "N" ]] || [[ "$YorNorR" == "n" ]]
    then
        exit 2
    fi
done

if ((ROLLMOD)) && [[ -d "$TEMPDIR/modules" ]]
then
    rsync --archive --links --delete "$TEMPDIR/modules" "$TF_DIR/"
    rm -rf "$TEMPDIR/modules"
fi

rsync --archive --links --delete $EXCLUDE "$TEMPDIR/"  "$TF_DIR/$DST"

if ((ROLLMOD))
then
    ln -sf "../modules" "$TF_DIR/$DST/modules"
fi

cd "$TF_DIR"
git status
