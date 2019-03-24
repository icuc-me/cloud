#!/bin/env python3

"""
Given a seed and count, output a uniform list of pseudo-random cidrs

Input must be a JSON map with values for the keys 'seed_string' and 'count'.
Output will be a JSON map with a single 'csv' key containing the cidr list.
The output list is guaranteed to be uniform, given identical input seed and count.
"""

import sys
import io
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
    if 'seed_string' not in query or 'count' not in query:
        errout('Query JSON input must contain "seed_string" and "count" values, found: {0}'
               "".format(query.keys()))
        sys.exit(1)
    else:
        seed_string = str(query['seed_string'])
        count = int(query['count'])
    return count, seed_string


class CidrCache:

    def __init__(self, string_seed):
        self.used_cidrs = set()
        # Rules for generating each cidr's set of bits
        self.cidr_sets = (set([10]),
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set([26]))
        crc32 = binascii.crc32(bytes(seed_string, encoding='utf-8')) & 0xFFFFFFFF
        self.random = random.Random(crc32)

    def _rand_cidr(self):
        cidr_bytes = [self.random.choice(tuple(self.cidr_sets[n])) for n in range(5)]
        # Validate and remove host bytes
        return ipaddress.IPv4Network("{}.{}.{}.{}/{}".format(*cidr_bytes),
                                     strict=False)

    def valid(self, cidr):
        return all((cidr.is_private,
                    not cidr.is_unspecified,
                    not cidr.is_global,
                    not cidr.is_multicast,
                    not cidr.is_loopback,
                    not cidr.is_link_local,
                    cidr.num_addresses >= 32,
                    cidr.with_prefixlen not in self.used_cidrs))

    def getone(self):
        cidr = self._rand_cidr()
        while not self.valid(cidr):
            cidr = self._rand_cidr()
        self.used_cidrs.add(cidr.with_prefixlen)
        return cidr.with_prefixlen


if __name__ == "__main__":
    count, seed_string = validate_input(json.load(sys.stdin))
    cache = CidrCache(seed_string)
    cidrs = [cache.getone() for n in range(count)]
    sys.stdout.write(json.dumps(dict(csv=",".join(cidrs)), skipkeys=True,
                                allow_nan=False, separators=(',',':')))
