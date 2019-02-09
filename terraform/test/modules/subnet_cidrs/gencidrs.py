#!/bin/env python3

import sys
import fcntl
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

        try:
            self.cachefile = io.open("/tmp/.cidrcache", "rt+")
        except FileNotFoundError:
            self.cachefile = io.open("/tmp/.cidrcache", "xt+")

        self.cidr_sets = (set([10]),
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set(range(0,128)) | set(range(129, 256)), # 128 is reserved
                          set([26]))

        crc32 = binascii.crc32(bytes(seed_string, encoding='utf-8')) & 0xFFFFFFFF
        self.random = random.Random(crc32)

    def fill(self):
        fcntl.flock(self.cachefile, fcntl.LOCK_EX)  # blocking
        for line in self.cachefile.readlines():
            line = ipaddress.IPv4Network(line.strip()).with_prefixlen
            self.used_cidrs.add(line)

    def flush(self, add_cidrs):
        self.cachefile.seek(0)
        self.cachefile.truncate(0)
        self.used_cidrs |= set(add_cidrs)
        for cidr in self.used_cidrs:
            self.cachefile.write('{}\n'.format(cidr))
        fcntl.flock(self.cachefile, fcntl.LOCK_UN)

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
    cache.fill()
    cidrs = [cache.getone() for n in range(count)]
    sys.stdout.write(json.dumps(dict(csv=",".join(cidrs)), skipkeys=True,
                                allow_nan=False, separators=(',',':')))
    cache.flush(cidrs)
