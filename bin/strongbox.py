#!/usr/bin/env python

import sys
import os
import shlex
from subprocess import check_output, Popen, CalledProcessError, PIPE, STDOUT
import simplejson as json

COMMON_GPG_ARGS = shlex.split("gpg2 --quiet --batch --armor"
                              " --cipher-algo=CAMELLIA256"
                              " --options=/dev/null")


def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))


def validate_input(query):
    for required in ('credentials', 'strongbox', 'strongkey'):
        if required not in query:
            raise RuntimeError("Required query key {0} not found in {1}"
                                   "".format(required, query.keys()))
    return dict(credentials=str(query['credentials']),
                strongbox=str(query['strongbox']),
                strongkey=str(query['strongkey']))


def activate_credentials(credentials):
    try:
        output = check_output(shlex.split("gcloud auth activate-service-account --key-file={0}"
                                          "".format(credentials)), stderr=STDOUT)
        return output
    except CalledProcessError as xcpt:
        errout('WARNING: {0}: {1}'.format(xcpt.cmd, xcpt.output))
        return None


def cat_bucket(uri):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, check_output(shlex.split("gsutil cat {0}".format(uri))))
    os.close(write_fd)
    return os.fdopen(read_fd)


def cat_key(key):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, str(key))
    os.close(write_fd)
    return os.fdopen(read_fd)


# Encrypt with:
# cat file.json | \
#     gpg2 --batch --quiet --options /dev/null \
#          --symmetric --cipher-algo CAMELLIA256 --armor --output - \
#          --passphrase-fd 42 42<<<"$STRONGKEY"

def decrypt(crypt_pipe, key_pipe):
    gpg_args = list(COMMON_GPG_ARGS)
    gpg_args += ["--decrypt", "--passphrase-fd={0}".format(key_pipe.fileno()), "--output=-"]
    return check_output(gpg_args, stdin=crypt_pipe)


if __name__ == "__main__":
    query = validate_input(json.load(sys.stdin))
    activate_credentials(str(query['credentials']))
    with cat_bucket(str(query['strongbox'])) as crypt_pipe, cat_key(str(query['strongkey'])) as key_pipe:
        # Validate format and output as expected
        plain_text = decrypt(crypt_pipe, key_pipe)
        json_in = json.loads(plain_text)
        json_out = json.dump(json_in, sys.stdout,
                             skipkeys=True, allow_nan=False, separators=(',',':'))
