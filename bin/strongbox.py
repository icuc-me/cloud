#!/usr/bin/env python

import sys
import os
import shlex
from subprocess import check_output, Popen, CalledProcessError, PIPE, STDOUT
import simplejson as json


CRYPTO_ALGO = "TWOFISH"
COMPRS_ALGO = "BZIP2"
COMMON_GPG_ARGS = shlex.split("gpg2 --quiet --batch --armor"
                              " --cipher-algo={0}"
                              " --compress-algo={1}"
                              " --options=/dev/null"
                              "".format(CRYPTO_ALGO, COMPRS_ALGO))


def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))

def validate_json(json_string):
    return json.dumps(json.loads(json_string),
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))

def validate_input(query):
    for required in ('credentials', 'strongkey'):
        if required not in query:
            errout('Required query key "{0}" not found in {1}'
                   "".format(required, query.keys()))
            sys.exit(1)
    sanitized = dict(credentials=str(query['credentials']),
                     strongkey=str(query['strongkey']))
    if 'plaintext' in query:
        try:
            sanitized['plaintext'] = validate_json(query['plaintext'])
        except ValueError as xcept:
            errout('Invalid JSON encoding of "plaintext" value: \'{0}\''
                    ''.format(str(query['plaintext'])))
            sys.exit(2)
    elif 'strongbox' in query:
        sanitized['strongbox'] = str(query['strongbox'])
    else:
        errout('ERROR: Expected JSON dictionary on stdin, having'
               ' keys/values for:\n       "credentials" and "strongkey"'
               ' then either "strongbox" or "plaintext"')
        sys.exit(3)

    return sanitized


def activate_credentials(credentials):
    args = shlex.split("gcloud auth activate-service-account --key-file={0}".format(credentials))
    try:
        output = check_output(args, stderr=STDOUT)
        return output
    except CalledProcessError as xcpt:  # credentials already activated
        errout('WARNING: {0}: {1}'.format(xcpt.cmd, xcpt.output))
        return None


def cat_bucket(uri):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, check_output(shlex.split("gsutil cat {0}".format(uri))))
    os.close(write_fd)
    return os.fdopen(read_fd)


def cat_string(key):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, str(key))
    os.close(write_fd)
    return os.fdopen(read_fd)

# Encrypt with:
# cat file.json | \
#     gpg2 --batch --quiet --options /dev/null \
#          --symmetric --cipher-algo CAMELLIA256 --armor --output - \
#          --passphrase-fd 42 42<<<"$STRONGKEY"
def encrypt(plain_pipe, key_pipe):
    gpg_args = list(COMMON_GPG_ARGS)
    gpg_args += ["--symmetric", "--passphrase-fd={0}".format(key_pipe.fileno()), "--output=-"]
    return check_output(gpg_args, stdin=plain_pipe)

def decrypt(crypt_pipe, key_pipe):
    gpg_args = list(COMMON_GPG_ARGS)
    gpg_args += ["--decrypt", "--passphrase-fd={0}".format(key_pipe.fileno()), "--output=-"]
    return check_output(gpg_args, stdin=crypt_pipe)


if __name__ == "__main__":
    query = validate_input(json.load(sys.stdin))
    if 'plaintext' in query:  # encrypt and present
        with cat_string(query['plaintext']) as plain_pipe, \
             cat_string(query['strongkey']) as key_pipe:

            crypt_text = encrypt(plain_pipe, key_pipe)
            sys.stdout.write(json.dumps(dict(encrypted=crypt_text), skipkeys=True,
                                        allow_nan=False, separators=(',',':')))

    else: # decrypt and present
        activate_credentials(str(query['credentials']))
        with cat_bucket(query['strongbox']) as crypt_pipe, \
             cat_string(query['strongkey']) as key_pipe:

            # Validate format and output as expected
            plain_text = decrypt(crypt_pipe, key_pipe)
            sys.stdout.write(validate_json(plain_text))
