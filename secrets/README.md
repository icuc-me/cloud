# Required files

## Contents of `*-provider.auto.tfvars`:

```
    zone
```

## Contents of `*-backend.auto.tfvars.in`:

May use `%%ENV_NAME%%`, `%%CREDS_DIRPATH%%`, and '%%UUID%%' substitution tokens in values,
as defined by Makefile.

```
    credentials
    project
    region
    bucket
```

## Google service account key files

Assumes separate projects for each environment with a suffix of "foobar",
and a service account username of "fng".  Create service accounts and keys
with the following commands, run from inside the ``secrets`` directory:

```
$ alias pgcloud='sudo podman run -it --rm -e AS_ID=$UID -e AS_USER=$USER --security-opt label=disable -v /home/$USER:$HOME -v /tmp:/tmp:ro quay.io/cevich/gcloud_centos:latest --configuration=$ENV_NAME --project=${ENV_NAME}${PROJECT_SFX}'
$ PROJECT_SFX=foobar
$ SUSERNAME=fng
$ ROLES="--role roles/editor"  # a lesser-privledged account will be created using this

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
