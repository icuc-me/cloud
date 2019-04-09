#!/bin/bash

set -e
source $(dirname $0)/lib.sh

[[ "${CI}" == "true" ]] || die "The script $(basename $0) is only intended for us under CI." 1
cd "$SRC_DIR"
make validate
