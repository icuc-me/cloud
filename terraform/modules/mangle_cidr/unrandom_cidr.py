#!/bin/env python3

import sys
import binascii
import random
import ipaddress
import simplejson as json

def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))

def validate_json(json_string):
    return json.dumps(json.loads(json_string),
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))

def validate_input(query):
    if 'seed_string' not in query:
        errout('Query JSON input must contain "seed_string" value, found: {0}'
               "".format(query.keys()))
        sys.exit(1)
    else:
        seed_string = str(query['seed_string'])
    return seed_string

class CidrCache:

    def __init__(self):
        self.cidrs = set()
        try:
            # Note: cache file assumed to go away between useful contexts
            self.cachefile = open("/tmp/.cidrcache", "r+")
        except FileNotFoundError:
            self.cachefile = open("/tmp/.cidrcache", "w+")

    def fill(self):
        self.cachefile.seek(0)
        for cidr in self.cachefile:
            self.cidrs.add(cidr)

    def flush(self, add_cidr):
        self.cachefile.truncate(0)
        for cidr in self.cidrs:
            self.cachefile.write('{}\n'.format(add_cidr))
        self.cachefile.write('{}\n'.format(add_cidr))

    def has(self, cidr):
        if cidr in self.cidrs:
            print("Sorry, {} has already been spoken for".format(cidr))
            return True
        return False


def string_seed(seed_string):
    crc32 = binascii.crc32(bytes(seed_string, encoding='utf-8')) & 0xFFFFFFFF
    random.seed(crc32)
    return crc32

def rand_cidr():
    cidr_octets = (10, random.randint(0,254),
                   random.randint(0,254), random.randint(0,254),
                   random.randint(8,28))
    rand = ipaddress.IPv4Network("{}.{}.{}.{}/{}".format(*cidr_octets), strict=False)
    return rand.with_prefixlen

if __name__ == "__main__":
    seed_string = validate_input(json.load(sys.stdin))
    string_seed(seed_string)
    cache = CidrCache()
    cache.fill()
    cidr = rand_cidr()
    while cache.has(cidr):
        cidr = rand_cidr()
    sys.stdout.write(json.dumps(dict(cidr=cidr), skipkeys=True,
                                allow_nan=False, separators=(',',':')))
    cache.flush(cidr)
