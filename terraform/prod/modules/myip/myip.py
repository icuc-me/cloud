#!/usr/bin/env python3

import sys
import requests
try:
    import simplejson as json
except ModuleNotFoundError:
    import json

URL='https://api.myip.com/'

def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))

def validate_json(json_string):
    return json.dumps(json.loads(json_string),
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))

if __name__ == "__main__":
    response = requests.get(URL)
    result = validate_json(str(response.json()).replace("'", '"'))
    sys.stdout.write(result)
    sys.stdout.write("\n")
