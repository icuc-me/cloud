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
* ``suser_display_name``: Full name / description to assign when creating the main service accounts
  for each project (test, stage, prod)
* ``ci_suser_display_name``: Human-friendly name for bot accounts (``*_ci_susername``)
* ``test_ci_susername``: Service account username for use by automated testing for test project.
* ``stage_ci_susername``: Service account username for use by automated testing for stage project.
* ``prod_ci_susername``: Service account username for use by automated testing for prod project.
* ``env_readers`` - Terraform 0.11 cannot accept anything except
  strings.  These are each encoded dictionaries containing a list of strings.
  The dictionaries are separated by `;`, the key and value by '=', and list items by ','.
  Each (possibly empty) list contains service account identities which should
  be granted read access to the cooresponding strongbox bucket and objects.
