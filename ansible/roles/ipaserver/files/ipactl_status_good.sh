#!/bin/bash

set -eo pipefail

/usr/sbin/ipactl status | while read LINE
do
    echo "$LINE" | egrep -iaq ":\s+RUNNING$" && \
        echo "GOOD: $LINE" && \
        continue
    echo "BAD: $LINE"
    exit 1
done
