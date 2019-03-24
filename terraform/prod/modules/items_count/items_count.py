#!/usr/bin/env python3

import sys
import os
import shlex
from subprocess import check_output, CalledProcessError, PIPE, STDOUT
from io import StringIO
import simplejson as json
from yaml import load


def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))

def validate_json(json_string):
    return json.dumps(json.loads(json_string),
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))

def validate_input(query):
    REQUIRED = ('string', 'delim')
    for required in REQUIRED:
        if required not in query:
            errout('Query JSON input must contain "{0}" key, got: "{1}"'
                   "".format(required, query))
            sys.exit(1)
    return dict(string=str(query['string']), delim=str(query['delim']))


if __name__ == "__main__":
    query = validate_input(json.load(sys.stdin))
    items = [str(item.strip())
             for item in query['string'].strip().split(query['delim'])
             if item.strip()]
    count = str(len(items))
    sys.stdout.write(json.dumps(dict(items=query['delim'].join(items), count=count), skipkeys=True,
                                allow_nan=False, separators=(',',':')))
