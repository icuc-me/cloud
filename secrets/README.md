# Requirements

## Google service account key files

Assumes separate projects for each environment with a suffix of "foobar",
and a service account username of "fng".  Create service accounts and keys
with the following commands, run from inside the ``secrets`` directory:

```

$ PROJECT_SFX=-foo-bar
$ SUSERNAME=fng
  # a lesser-privledged account is used for testing
$ SUPERSERVICE=${SUSERNAME}@prod${PROJECT_SFX}.iam.gserviceaccount.com
$ ROLES="\
--role=roles/compute.admin
--role=roles/compute.networkAdmin
--role=roles/storage.admin
--role=roles/storage.objectAdmin
--role=roles/iam.serviceAccountUser
--role=roles/iam.serviceAccountAdmin
--role=roles/resourcemanager.projectIamAdmin"

$ alias pgcloud='sudo podman run -i --rm -e AS_ID=$UID -e AS_USER=$USER --security-opt label=disable
 -v /home/$USER:$HOME -v /tmp:/tmp:ro quay.io/cevich/gcloud_centos:latest
 --configuration=${ENV_NAME} --project=${ENV_NAME}${PROJECT_SFX}'

$   pgcloud init --skip-diagnostics; \
    pgcloud iam service-accounts create ${SUSERNAME}; \
    pgcloud iam service-accounts keys create \
        $PWD/${SUSERNAME}.json \
        --iam-account=serviceAccount:$SUPERSERVICE \
        --key-file-type=json; \
$ for ENV_NAME in prod stage test; do
    for ROLE in $ROLES; do \
        pgcloud projects add-iam-policy-binding ${ENV_NAME}${PROJECT_SFX} \
                --quiet --member serviceAccount:${SUPERSERVICE} $ROLE;  done; \
    pgcloud projects get-iam-policy ${ENV_NAME}${PROJECT_SFX} \
           --flatten="bindings[].members" --format='table(bindings.role)' \
           --filter="bindings.members:$SUPERSERVICE"; \
    done
```

## Contents of `*-secrets.sh`:

Where `*` represents an environment name (test, stage, or prod), values
for all of the following are required.

```bash
CREDENTIALS=  # Name of credentials JSON key file (from above)
SUSERNAME=    # Service account name matching $CREDENTIALS
STRONGBOX=    # Name of the bucket containing strongbox file for this environment
STRONGKEY=    # Encryption key securing contents of this env. strong box file
PROJECT=      # GCP project ID
REGION=       # Default GCE region
ZONE=         # Default GCE zone
BUCKET=       # Name of terraform backend bucket
PREFIX=       # Folder in bucket to store state
UUID=         # Unique ID for environment instance
```

## Strongboxes

All sensitive values not stored in the secrets scripts, are YAML encoded in three
files - one per environment.  Each must contain the following values:

* ``env_name``: name of the environment - validated against ``ENV_NAME`` at runtime
* ``fqdn``: Top-most DNS domain to manage in google cloud DNS
* ``legacy_domains``: CSV of legacy fqdns to manage with CNAMES into fqdn
* ``ci_suser_display_name``: Human-friendly name for bot accounts (``*_ci_susername``)
* ``test_ci_susername``: Service account username for use by automated testing for test project.
* ``stage_ci_susername``: Service account username for use by automated testing for stage project.
* ``prod_ci_susername``: Service account username for use by automated testing for prod project.
* ``env_readers`` - Terraform 0.11 cannot accept anything except
  strings.  These are each encoded dictionaries containing a list of strings.
  The dictionaries are separated by `;`, the key and value by '=', and list items by ','.
  Each (possibly empty) list contains service account identities which should
  be granted read access to the cooresponding strongbox bucket and objects.

### Encryption / Decryption

Openssl and python3 are required, and the google sdk is recommended.  Given a strongbox *yaml*
file.  The following pipeline will encrypt and load the output into a bucket object.  Be sure
to execute these within the proper environment, since openssl encryption is (unfortunately)
highly version-dependent.

```
$ IN=test-strongbox.yml
$ SB=test.v2.txt
$ BU=gs://foobarbaz
$ cat "$IN" | \
    python3 -c 'import sys,json,yaml;json.dump(yaml.load(sys.stdin),sys.stdout,indent=2);' | \
    openssl enc -aes-256-cbc -base64 -e | \
    gsutil cp - "$BU/$SB"
```

Assuming the same password/passphrase is used, the following will decrypt the remote
bucket contents into a local strongbox file.

```
$ OUT=test-strongbox.yml
$ BU=gs://foobarbaz
$ SB=test.v2.txt
$ gsutil cat "$BU/$SB" | \
    openssl enc -aes-256-cbc -base64 -d | \
    python3 -c 'import sys,json,yaml;yaml.dump(json.load(sys.stdin),sys.stdout);' \
    > "$OUT"
```
