# Requirements

## Google service account key files

Assumes separate projects for each environment with a suffix of "foobar",
and a service account username of "fng".  Create service accounts and keys
with the following commands, run from inside the ``secrets`` directory:

```
$ alias pgcloud='sudo podman run -it --rm -e AS_ID=$UID -e AS_USER=$USER --security-opt label=disable -v /home/$USER:$HOME -v /tmp:/tmp:ro quay.io/cevich/gcloud_centos:latest --configuration=$ENV_NAME --project=${ENV_NAME}${PROJECT_SFX}'
$ PROJECT_SFX=foobar
$ SUSERNAME=fng
  # a lesser-privledged account is used for testing
$ ROLES="
    --role roles/compute.admin
    --role roles/compute.networkAdmin
    --role roles/iam.serviceAccountUser
    --role roles/storage.admin"

$ for ENV_NAME in test stage prod; do \
    pgcloud init --skip-diagnostics; \
    pgcloud iam service-accounts create ${SUSERNAME}; \
    pgcloud iam service-accounts keys create \
        $PWD/${ENV_NAME}-${SUSERNAME}.json \
        --iam-account=serviceAccount:${SUSERNAME}@${ENV_NAME}${PROJECT_SFX}.iam.gserviceaccount.com \
        --key-file-type=json; \
    pgcloud projects add-iam-policy-binding ${ENV_NAME}${PROJECT_SFX} \
        --member serviceAccount:${SUSERNAME}@${ENV_NAME}${PROJECT_SFX}.iam.gserviceaccount.com \
        $ROLES; \
done
```

A handy command for listing roles bound to a service account is:

```
$ gcloud projects get-iam-policy ${ENV_NAME}${PROJECT_SFX} \
--flatten="bindings[].members" --format='table(bindings.role)' \
--filter="bindings.members:${SUSERNAME}@${ENV_NAME}${PROJECT_SFX}.iam.gserviceaccount.com"
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
