#!/usr/bin/env python3

import sys
import os
import shlex
from subprocess import check_output, Popen, CalledProcessError, PIPE, STDOUT
from io import StringIO
import simplejson as json
from yaml import load


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

def validate_yaml(yaml_string):
    yaml_obj = load(StringIO(str(yaml_string)))
    return json.dumps(yaml_obj,
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))

def validate_input(query):
    if 'strongkey' not in query:
        errout('Query JSON input must contain "strongkey" value, found: {0}'
               "".format(query.keys()))
        sys.exit(1)
    else:
        sanitized = dict(strongkey=str(query['strongkey']))
    if 'plaintext' in query:
        try:
            sanitized['plaintext'] = validate_json(validate_yaml(query['plaintext']))
        except ValueError as xcept:
            errout('Invalid YAML or JSON encoding of "plaintext" value: \'{0}\''
                    ''.format(str(query['plaintext'])))
            sys.exit(2)
    elif 'strongbox' in query and 'credentials' in query:
        sanitized['strongbox'] = str(query['strongbox'])
        sanitized['credentials'] = str(query['credentials'])
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
    args = shlex.split("gsutil cat {0}".format(uri))
    os.write(write_fd, bytes(check_output(args), 'utf-8'))
    os.close(write_fd)
    return os.fdopen(read_fd)


def cat_string(key):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, bytes(str(key), 'utf-8'))
    os.close(write_fd)
    return os.fdopen(read_fd)

def encrypt(plain_pipe, key_pipe):
    gpg_args = list(COMMON_GPG_ARGS)
    gpg_args += ["--symmetric", "--passphrase-fd={0}".format(key_pipe.fileno()), "--output=-"]
    return check_output(gpg_args, stdin=plain_pipe.fileno())

def decrypt(crypt_pipe, key_pipe):
    gpg_args = list(COMMON_GPG_ARGS)
    gpg_args += ["--decrypt", "--passphrase-fd={0}".format(key_pipe.fileno()), "--output=-"]
    return check_output(gpg_args, stdin=crypt_pipe.fileno())


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
            try:
                plain_text = decrypt(crypt_pipe, key_pipe)
                sys.stdout.write(validate_json(plain_text))
            except CalledProcessError:
                errout("Decryption of {} failed with key {}"
                       "".format(query['strongbox'], query['strongkey']))
                raise
