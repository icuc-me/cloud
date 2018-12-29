#!/bin/bash

# This script is intended to be used by automation, performing all prepretory work
# as needed, prior to executing terraform.  Alternately, if called as 'teardown.sh'
# it will reverse the process.  No checks are performed, care should be taken not
# to execute this against valuable data

set -e

source $(dirname $0)/lib.sh

[[ -r "$1" ]] || die "Must passs terraform backend configuration as parameter" 1
BACKEND_FILEPATH="$1"

tfvar_value() {
    cat "$BACKEND_FILEPATH" | grep -m 1 "$1" | sed -re "s/^$1\s*=\s*//g" | tr -d \'\"
}

set_tfvars() {
    credentials="$(tfvar_value credentials)"
    project="$(tfvar_value project)"
    region="$(tfvar_value region)"
    bucket="$(tfvar_value bucket)"
    prefix="$(tfvar_value prefix)"
}

init_gcloud() {
    if [[ -r $HOME/.config/gcloud/configurations/config_default ]]
    then
        echo "gcloud already configured"
    else
        gcloud auth activate-service-account --key-file="$credentials"
        gcloud config set project "$project"
        gcloud config set region "$region"
    fi
}

create_bucket() {
    if gsutil ls | grep "$bucket"
    then
        echo "Bucket $bucket already exists"
    else
        gsutil mb gs://$bucket
    fi
}

teardown_bucket() {
    if gsutil ls | grep "$bucket"
    then
        gsutil rm -arf gs://$bucket
    else
        echo "Bucket $bucket doesn't exist"
    fi
}

#### MAIN

if [[ "$0" =~ "prep" ]]
then
    set_tfvars
    init_gcloud
    create_bucket
elif [[ "$0" =~ "teardown" ]]
then
    set_tfvars
    init_gcloud
    teardown_bucket
else
    echo "Not sure how to $0"
    exit 1
fi
