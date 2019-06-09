#!/bin/bash

set -eo pipefail

source $(dirname $0)/lib.sh

[[ "${CI}" == "true" ]] || die "The script $(basename $0) is only intended for us under CI." 1
[[ -d "$CIRRUS_WORKING_DIR" ]] || die "Not a directory: $CIRRUS_WORKING_DIR" 3
[[ -n "$1" ]] || die "Need subcommand as first argument" 5
[[ -n "$REG_NS" ]] || \
    die "Expecting non-empty \$REG_NS" 37
[[ -n "$IMG_TAG" ]] || \
    die "Expecting non-empty \$IMG_TAG" 36
[[ -n "$TEST_IMG_TAG" ]] || \
    die "Expecting non-empty \$TEST_IMG_TAG" 36

if [[ "$1" != "push" ]]
then  # We should use skopeo
    [[ "$(type -P skopeo)" ]] || \
        die "Cannot find skopeo binary" 39
fi

echo "Select environment variables:"
show_env

case "$1" in
    setup)
        echo "Configuring credentials"
        bin/env_file.sh TEST_SECRETS "$CIRRUS_WORKING_DIR/secrets/test-secrets.sh"
        unset TEST_SECRETS
        bin/env_file.sh TEST_CREDS "$CIRRUS_WORKING_DIR/secrets/50bdcb31cd804734a41ad420bc35fae7.json"
        unset TEST_CREDS
        echo "Recovering cached go directories"
        mkdir -p "$(go env GOPATH)"
        rsync --recursive --links --safe-links --sparse "/usr/src/go/" "$(go env GOPATH)"
        mkdir -p "$(go env GOCACHE)"
        rsync --recursive --links --safe-links --sparse "/var/cache/go/" "$(go env GOCACHE)"
        echo "setup done"
        ;;
    verify)
        echo "Verifing repository/files/environment"
        cd $CIRRUS_WORKING_DIR/validate
        make verify ANCESTOR_BRANCH_COMMIT=$CIRRUS_BASE_SHA HEAD_COMMIT=$CIRRUS_CHANGE_IN_REPO
        ;;
    lint)
        echo "Checking for lint"
        cd $CIRRUS_WORKING_DIR/validate
        make lint
        ;;
    deploy)
        echo "Deploying test environment"
        cd $CIRRUS_WORKING_DIR
        make test_env
        ;;
    smoke)
        echo "Smoking test environment"
        cd $CIRRUS_WORKING_DIR/validate
        make smoke
        ;;
    validate)
        echo "Validating test environment"
        cd $CIRRUS_WORKING_DIR/validate
        make validate
        ;;
    clean)
        echo "Cleaning test environment"
        cd $CIRRUS_WORKING_DIR
        make test_clean
        ;;
    tag)
        [[ "$VERSION_MAJ" -gt "0" ]] || \
            die "Refusing to tag ephemeral version with 'latest': $VERSION_MAJ" 38
        reg_login
        for name in "$BASE_IN" "$TOOLS_IN" "$RUN_IN"
        do
            [[ -n "$name" ]] || die "Expecting non-empty \$name" 44
            echo "Tagging '$REG_NS/$name:$IMG_TAG' -> 'latest'"
            retry.sh 300 3 120 sudo skopeo copy "docker://$REG_NS/$name:$IMG_TAG" "docker://$REG_NS/$name:latest"
        done
        ;;
    untag)
        echo "Removing testing image"
        [[ "$VERSION_MAJ" -ne "0" ]] || [[ "$IMG_TAG" == "latest" ]] || \
            die "Refusing to delete non-ephemeral image" 38
        reg_login
        for name in "$BASE_IN" "$TOOLS_IN" "$RUN_IN"
        do
            [[ -n "$name" ]] || die "Expecting non-empty \$name" 40
            echo "Deleting '$REG_NS/$name:$IMG_TAG'"
            retry.sh 30 10 30 sudo skopeo delete "docker://$REG_NS/$name:$IMG_TAG" &
            if [[ "$IMG_TAG" != "$TEST_IMG_TAG" ]]
            then
                echo "Deleting '$REG_NS/$name:$TEST_IMG_TAG'"
                retry.sh 30 10 30 sudo skopeo delete "docker://$REG_NS/$name:$TEST_IMG_TAG" &
            fi
        done
        wait
        ;;
    push)
        echo "Pushing built container images using docker"
        reg_login
        for name in "$BASE_IN" "$TOOLS_IN" "$RUN_IN"
        do
            [[ -n "$name" ]] || die "Expecting non-empty \$name" 43
            retry.sh 300 3 120 $CONTAINER push "$REG_NS/$name:$IMG_TAG"
            [[ "$IMG_TAG" == "$TEST_IMG_TAG" ]] || \
                retry.sh 300 3 120 sudo $CONTAINER push "$REG_NS/$name:$TEST_IMG_TAG"
        done
        ;;
    *)
        die "Unknown subcommand: $1" 7
        ;;
esac
