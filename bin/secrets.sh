#!/bin/bash

set -e

source "$(dirname $0)/lib.sh"

ENVS="$@"
BACKEND="$1"
SECRETS_SUBDIR="secrets"
ERRVAL="ERROR-MISSING-VALUE"
BACKENDFN="$BACKEND-backend.auto.tfvars"
RUNTIMEFN="$BACKEND-runtime.auto.tfvars"
TMPDIR=$(mktemp -d -p '' ${SCRIPT_FILENAME}_XXXX)
cleanup() {
    echo "Cleaning up"
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$SRC_DIR/$SECRETS_SUBDIR"

check_missing() {
    [[ -n "$1" ]] || die "Missing environment name to check" 12
    [[ -n "$2" ]] || die "Missing filename to check" 13
    MISSING=$(grep "$ERRVAL" "$2" || echo "")
    [[ -z "$MISSING" ]] || die "ERROR: Missing expected value(s) in ${ENV}-secrets.sh: $MISSING" 13
}

gen_backend() {
    [[ -n "$1" ]] || die "Missing backend environment name" 4
    export ENV="$1"
    source "${ENV}-secrets.sh"
    echo "Generating Backend configuration for $ENV environment"
    cat << EOF > "$TMPDIR/$BACKENDFN"
# BEGIN GENERATED BACKEND FOR $ENV - MANUAL CHANGES WILL BE LOST

credentials = "$SRC_DIR/$SECRETS_SUBDIR/${CREDENTIALS:-$ERRVAL}"
project = "${PROJECT:-$ERRVAL}"
region = "${REGION:-$ERRVAL}"
bucket = "${BUCKET:-$ERRVAL}"
prefix = "${PREFIX:-$ERRVAL}"

# END GENERATED BACKEND CONFIG FOR $ENV - MANUAL CHANGES WILL BE LOST
EOF
    check_missing "$ENV" "$TMPDIR/$BACKENDFN"
}

gen_runtime_head() {
    [[ -n "$1" ]] || die "Missing head runtime environment name" 8
    export ENV="$1"
    echo "Generating runtime configuration for $ENV environment"
    source "${ENV}-secrets.sh"
    cat << EOF > "$TMPDIR/$RUNTIMEFN"
# BEGIN GENERATED CONFIG FOR $ENV - MANUAL CHANGES WILL BE LOST

UUID = "${UUID:-$ERRVAL}"
ENV_NAME = "${BACKEND:-$ERRVAL}"
SRC_VERSION = "$VERSION"

EOF
}

gen_runtime_body() {
    [[ -n "$1" ]] || die "Missing runtime environment name" 9
    export ENV="$1"
    echo "    Adding $ENV variables"
    gen_runtime_body_map $ENV >> "$TMPDIR/$RUNTIMEFN"
    echo "" >> "$TMPDIR/$RUNTIMEFN"
}

gen_runtime_body_map() {
    [[ -n "$1" ]] || die "Missing body-map runtime environment name" 11
    export ENV="$1"
    source "${ENV}-secrets.sh"
    cat << EOF >> "$TMPDIR/$RUNTIMEFN"
$(echo $ENV | tr [[:lower:]] [[:upper:]])_SECRETS = {
    CREDENTIALS = "$SRC_DIR/$SECRETS_SUBDIR/${CREDENTIALS:-$ERRVAL}"
    SUSERNAME = "${SUSERNAME:-$ERRVAL}"
    PROJECT = "${PROJECT:-$ERRVAL}"
    REGION = "${REGION:-$ERRVAL}"
    ZONE = "${ZONE:-$ERRVAL}"
    BUCKET = "${BUCKET:-$ERRVAL}"
    UUID = "${UUID:-$ERRVAL}"
}
EOF
    check_missing "$ENV" "$TMPDIR/$RUNTIMEFN"
}

gen_runtime_tail() {
    [[ -n "$1" ]] || die "Missing tail runtime environment name" 13
    export ENV="$1"
    source "${ENV}-secrets.sh"
    cat << EOF >> "$TMPDIR/$RUNTIMEFN"
# END GENERATED CONFIG FOR $ENV - MANUAL CHANGES WILL BE LOST
EOF
    check_missing "$ENV" "$TMPDIR/$RUNTIMEFN"
}


##### MAIN

[[ "$#" -ge "1" ]] || die "Must specify at least one environment name (test, stage, or prod)" 5

for (( i=1; i <= $# && i <= 3; i++ ))
do
    ENV=$1
    shift
    echo "$ENV" | egrep -q "(test)|(stage)|(prod)" || \
        die "Usage: $SCRIPT_FILENAME [ test | stage | prod ]...  # first specified is backend" $i
    [[ -r "${ENV}-secrets.sh" ]] || die "Unable to open $SRC_DIR/$SECRETS_SUBDIR/${ENV}-secrets.sh" 6
done

gen_backend "$BACKEND"

gen_runtime_head "$BACKEND"

for ENV in $ENVS
do
    gen_runtime_body $ENV
done

gen_runtime_tail "$BACKEND"

mv -f "$TMPDIR"/"$BACKEND-"*.auto.tfvars "$SRC_DIR/$SECRETS_SUBDIR/"
