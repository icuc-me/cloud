#!/bin/bash

set -e

MAXTEMP=${MAXTEMP:-50}  # Celsius
METRICS="lmsensors.coretemp_isa.temp2 lmsensors.coretemp_isa.temp4"

type -P pminfo &> /dev/null || \
    ( echo "Expecting pminfo command to be available" && exit 1 )

HIGHESTTEMP=${HIGHESTTEMP:-$(pminfo -f $METRICS | grep value | awk -e '{print $2}' | sort -n | tail -1)}
touch $HOME/thermals.log
tail -47 $HOME/thermals.log > $HOME/.thermals.log.tmp
echo "$(date --iso-8601=minutes): Highest system temperature '$HIGHESTTEMP' (C)" \
    >> $HOME/.thermals.log.tmp
mv $HOME/.thermals.log.tmp $HOME/thermals.log

if [[ "$HIGHESTTEMP" -ge "$MAXTEMP" ]]
then
    echo "WARNING: Maximum temperature of $MAXTEMP exceeded, currently: $HIGHESTTEMP"
    exit 2
fi
