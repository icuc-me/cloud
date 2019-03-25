#!/usr/bin/env python3

"""Remove items from k_csv and v_csv where the v_csv item matches v_re"""

import sys
import os
import shlex
import re
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
    REQUIRED = ('k_csv', 'v_csv', 'v_re', 'delim')
    for required in REQUIRED:
        if required not in query:
            errout('Query JSON input must contain "{0}" key, got: "{1}"'
                   "".format(required, query))
            sys.exit(1)
    sanitized = dict(
            delim=str(query['delim']),
            k=str(query['k_csv']).split(str(query['delim'])),
            v=str(query['v_csv']).split(str(query['delim'])),
            re=re.compile(str(query['v_re']))
    )
    return sanitized

if __name__ == "__main__":
    query = validate_input(json.load(sys.stdin))
    try:
        assert len(query['k']) == len(query['v'])
    except AssertionError:
        raise AssertionError("(length) {0} != {1}".format(query['k'], query['v']))

    k_result = []
    v_result = []
    for i, k in enumerate(query['k']):
        v = query['v'][i].strip()
        if query['re'].search(v):
            continue
        k_result.append(k)
        v_result.append(v)

    result = dict(
        k_csv=query['delim'].join(k_result),
        v_csv=query['delim'].join(v_result),
        count=str(len(k_result))
    )
    sys.stdout.write(json.dumps(result, skipkeys=True,
                                allow_nan=False, separators=(',',':')))
