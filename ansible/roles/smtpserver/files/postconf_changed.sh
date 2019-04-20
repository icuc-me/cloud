#!/bin/bash

DEFAULTS=$(postconf -d)
postconf -n | while read ACTUAL
do
    KEY=$(echo "$ACTUAL" | cut -d = -f 1 | tr -d [:space:])
    DEFAULT=$(echo "$DEFAULTS" | grep "^$KEY =")
    [ "$ACTUAL" == "$DEFAULT" ] || echo "$ACTUAL"
done
