#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"

STATUS="ERROR"
RESULT=$(mktemp -p '' $(basename $SCRIPT_FILENAME)_RESULT_XXXXXX)
NEEDCLEAN=$(mktemp -p '' $(basename $SCRIPT_FILENAME)_NEEDCLEAN_XXXXXX)
echo 0 | tee "$NEEDCLEAN" > "$RESULT"

notgood() {
    if [[ $(cat "$RESULT") -eq "0" ]]
    then
        return 1
    fi
}

good() {
    if [[ $(cat "$RESULT") -gt "0" ]]
    then
        return 1
    fi
}

cleanup() {
    cd "$SRC_DIR"
    indent 1 "Cleaning up"
    if [[ $(cat "$NEEDCLEAN") -ne "0" ]]
    then
        indent 2 "Cleaning up test environment"
        make test_clean || \
            indent 2 "WARNING: Test Environment cleanup failed, manual resource recover may be required"
    fi
    indent 2 "Removing temporary files"
    rm -f "$RESULT"
    rm -f "$NEEDCLEAN"
    indent 2 "WARNING: 'make clean' has not been run"
    echo
    indent 1 "$STATUS"
}

set +e

[[ -z "$1" ]] || [[ "$1" == "--nolint" ]] || [[ "$1" == "--lintonly" ]] || \
    die "Usage: $(basename $0) [--nolint | --lintonly]" 1

echo "0" > "$RESULT"
trap cleanup EXIT

if [[ "$1" != "--nolint" ]]
then
    indent 1 "Checking source condition and lint (skip with --nolint)"
    cd "$SCRIPT_DIRPATH"
    make verify && make lint
    echo "$?" > "$RESULT"
fi


if good && [[ "$1" != "--lintonly" ]]
then
    STATUS="FAIL: -  |  PASS: lint"
    indent 2 "Creating test environment (skip with --lintonly)"
    cd "$SRC_DIR"
    make test_env
    echo "$?" > "$RESULT"
    echo 1 > "$NEEDCLEAN"

    if good
    then
        STATUS="FAIL: -  |  PASS: lint create"
        indent 3 "Smoke testing test environment"
        cd "$SCRIPT_DIRPATH"
        make smoke
        echo "$?" > "$RESULT"

        if good
        then
            STATUS="FAIL: -  |  PASS: lint create smoke"
            indent 3 "Test environment smoke testing: PASS"

            indent 4 "Validating test environment"
            make validate
            if good
            then
                STATUS="FAIL: -  |  PASS: lint create smoke validate"
                indent 4 "Test environment validation: PASS"
            else
                STATUS="FAIL: validate  |  PASS: lint create smoke"
                indent 4 "Tests environment validation: FAIL"
                exit 4
            fi
        else
            STATUS="FAIL: smoke  |  PASS: lint create"
            indent 3 "Test environment smoke testing: FAIL"
            exit 3
        fi

    else
        STATUS="FAIL: create  |  PASS: lint"
        indent 2 "Failed to create test environment"
        exit 2
    fi
else
    STATUS="FAIL: lint  |  PASS: -"
    indent 1 "Failed verify or lint check"
    exit 1
fi
