#!/usr/bin/env python3

import sys
import os
import shlex
from subprocess import check_output, CalledProcessError, PIPE, STDOUT
from io import StringIO
try:
    import simplejson as json
except ModuleNotFoundError:
    import json

def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))
from yaml import safe_load

DEFAULT_TIMEOUT = 5
CRYPT_CHARS = 60
COMMON_ARGS = shlex.split("openssl enc -aes-256-cbc -A -base64")


def errout(msg):
    sys.stderr.write('{0}\n'.format(msg))


def validate_json(json_string):
    return json.dumps(json.loads(json_string),
                      skipkeys=True, allow_nan=False,
                      separators=(',',':'))


def validate_yaml(yaml_string):
    yaml_obj = safe_load(StringIO(yaml_string))
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
               ' keys/values for:\n       "strongkey" then,  either "plaintext"'
               ' or "credentials" and "strongbox"')
        sys.exit(3)

    return sanitized


def activate_credentials(credentials):
    args = shlex.split("gcloud auth activate-service-account --key-file={0}".format(credentials))
    try:
        output = str(check_output(args, stderr=STDOUT, close_fds=False))
        return output
    except CalledProcessError as xcpt:  # credentials already activated
        errout('WARNING: {0}: {1}'.format(xcpt.cmd, xcpt.output))
        return None


def cat_bucket(uri):
    read_fd, write_fd = os.pipe()
    args = shlex.split("gsutil cat {0}".format(uri))
    contents = str(check_output(args, close_fds=False), encoding='utf-8').replace('\n','')
    os.write(write_fd, bytes(contents, encoding='utf-8'))
    os.close(write_fd)
    os.set_inheritable(read_fd, True)
    return os.fdopen(read_fd, mode='rt', encoding='utf-8')


def cat_string(key):
    read_fd, write_fd = os.pipe()
    os.write(write_fd, bytes(key, encoding='utf-8'))
    os.close(write_fd)
    os.set_inheritable(read_fd, True)
    return os.fdopen(read_fd, mode='rt', encoding='utf-8')


def encrypt(plain_pipe, key_pipe):
    cmd_args = list(COMMON_ARGS)
    cmd_args += ["-e", "-pass", "fd:{0}".format(key_pipe.fileno())]
    cypher_text = str(check_output(cmd_args, stdin=plain_pipe.fileno(), close_fds=False),
                      encoding='utf-8')
    return '\n'.join([cypher_text[i:i+CRYPT_CHARS] for i in range(0, len(cypher_text), CRYPT_CHARS)])


def decrypt(crypt_pipe, key_pipe):
    cmd_args = list(COMMON_ARGS)
    cmd_args += ["-d", "-pass", "fd:{0}".format(key_pipe.fileno())]
    plain_text = check_output(cmd_args, stdin=crypt_pipe.fileno(), close_fds=False,
                              encoding='utf-8')
    return plain_text

if __name__ == "__main__":
    query = validate_input(json.load(sys.stdin))

    if 'plaintext' in query:  # encrypt and present
        with cat_string(query['plaintext']) as plain_pipe, \
             cat_string(query['strongkey']) as key_pipe:

            crypt_text = encrypt(plain_pipe, key_pipe)
            sys.stdout.write(json.dumps(dict(encrypted=crypt_text), skipkeys=True,
                                        allow_nan=False, separators=(',',':')))
            sys.stdout.write("\n")

    else: # decrypt and present
        activate_credentials(str(query['credentials']))
        with cat_bucket(query['strongbox']) as crypt_pipe, \
             cat_string(query['strongkey']) as key_pipe:

            # Validate format and output as expected
            try:
                plain_text = str(decrypt(crypt_pipe, key_pipe))
                try:
                    sys.stdout.write(validate_json(plain_text))
                    sys.stdout.write("\n")
                except json.decoder.JSONDecodeError:
                    errout("Failed to parse contents: {0}".format(plain_text))
                    raise
            except CalledProcessError:
                errout("Decryption of {} failed"
                       "".format(query['strongbox']))
                raise
