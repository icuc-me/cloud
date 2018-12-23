# Required files

## Contents of `provider.auto.tfvars`:

```
    zone
```

## Contents of `backend.auto.tfvars.in`:

May use `%%ENV_NAME%%` and `%%CWD_PATH` substitution tokens in values

```
    credentials
    project
    region
    bucket
```

## Google service account key files

Assumes separate projects for each environment with a suffix of "foobar",
and a service account username of "fng".  Create service accounts and keys
with the following commands:

```
$ alias pgcloud='sudo podman run -it --rm -e AS_ID=$UID -e AS_USER=$USER --security-opt label=disable -v /home/$USER:$HOME -v /tmp:/tmp:ro quay.io/cevich/gcloud_centos:latest'

$ PROJECT_SFX=foobar
$ SUSERNAME=fng

$ for ENV_NAME in test stage prod; do \
pgcloud --configuration=$ENV_NAME --project=${ENV_NAME}-${PROJECT_SFX} init; \
pgcloud --configuration=prod iam service-accounts create ${SUSERNAME}; \
pgcloud --configuration=$ENV_NAME iam service-accounts keys create \
    $PWD/${ENV_NAME}-${SUSERNAME}.json \
    --iam-account=${SUSERNAME}@${ENV_NAME}-cloud-icuc-me.iam.gserviceaccount.com \
    --key-file-type=json; done
```
