#!/bin/bash

set +x
set -eo pipefail

source $(dirname $0)/lib.sh

ENVVAR="$1"
FILEPATH="$2"

[[ -n "$ENVVAR" ]] || die "First parameter must be name of env. var. to read" 1
eval "CONTENTS=\${$ENVVAR}"
[[ -n "${CONTENTS}" ]] || die "First parameter env. var. contents must not be empty" 2
[[ -n "$FILEPATH" ]] || die "Second parameter must be path to file to write" 3
[[ -d "$(dirname $FILEPATH)" ]] || die "Directory containing $FILEPATH does not exist" 4

cd "$SRC_DIR"
echo "$CONTENTS" > "$FILEPATH"
