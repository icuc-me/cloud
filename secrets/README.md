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
$ ROLES="--role roles/editor --role roles/storage.admin"

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

## Contents of `*-secrets.sh`:

Where `*` represents an environment name (test, stage, or prod), values
for all of the following are required.

```bash
CREDENTIALS=  # Name of credentials JSON key file (from above)
SUSERNAME=    # Service account name matching $CREDENTIALS
STRONGBOX=    # URI to Strong Box
STRONGKEY=    # Auth. key to Strong Box
PROJECT=      # GCP project ID
REGION=       # Default GCE region
ZONE=         # Default GCE zone
BUCKET=       # Name of terraform backend bucket
PREFIX=       # Folder in bucket to store state
UUID=         # Unique ID for environment instance
```
