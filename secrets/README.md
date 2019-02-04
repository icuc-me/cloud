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
    --role roles/storage.admin
    --role roles/iam.serviceAccountAdmin"

$ SUPERSERVICE=$SUSERNAME@prod${PROJECT_SFX}.iam.gserviceaccount.com

$ for ENV_NAME in prod stage test; do \
    pgcloud init --skip-diagnostics; \
    pgcloud iam service-accounts create ${SUSERNAME}; \
    pgcloud iam service-accounts keys create \
        $PWD/${ENV_NAME}-${SUSERNAME}.json \
        --iam-account=serviceAccount:${SUSERNAME}@${ENV_NAME}${PROJECT_SFX}.iam.gserviceaccount.com \
        --key-file-type=json; \
    pgcloud projects add-iam-policy-binding ${ENV_NAME}${PROJECT_SFX} \
        --member serviceAccount:${SUSERNAME}@${ENV_NAME}${PROJECT_SFX}.iam.gserviceaccount.com \
        $ROLES; \
    pgcloud projects add-iam-policy-binding ${ENV_NAME}${PROJECT_SFX} \
        --member serviceAccount:${SUPERSERVICE} \
        --role roles/resourcemanager.projectIamAdmin;
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
* ``suser_display_name``: Full name / description to assign when creating the main service accounts
  for each project (test, stage, prod)
* ``test_roles_members_bindings`` - see below
* ``stage_roles_members_bindings`` - see below
* ``prod_roles_members_bindings`` - Terraform 0.11 cannot accept anything except
  but effectively these are each dictionaries containing a list of strongs.
  The dictionaries are separated by `;`, the key and value by '=', and list items by ','.
  Keys should be the names of canned or custom Google IAM roles.  Items are a list
  of identities assigned to the role.  See the
  [terraform google_project_iam_binding documentation](https://www.terraform.io/docs/providers/google/r/google_project_iam.html#google_project_iam_binding)
  for the required identity format.
