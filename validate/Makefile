
.PHONY: all
all: help

.PHONY: help
help:
	@echo '###########################################################################'
	@echo 'Valid Make Targets:'
	@echo ''
	@echo 'format - Correct formatting of source files'
	@echo 'verify - Confirm working paths, commits, and formats are ok'
	@echo 'lint - Verify lint in all source files'
	@echo 'smoke - execute smoke tests'
	@echo 'validate - execute all environment validation tests'
	@echo '###########################################################################'

GOPATH=$(shell go env GOPATH))
GOBIN=$(shell go env GOBIN))
PROJECT=github.com/icuc-me/cloud/validate
SRC_DIR=$(shell realpath "../")
# TODO: OVERIDE this from value provided by CI system
ANCESTOR_BRANCH_COMMIT?=$(shell git merge-base origin/master HEAD)
SEED=$(shell date +%s)
TESTVERBOSE?=0

.PHONY: clean
clean:
	rm -f .pathok verify lint smoke validate.test

.pathok: $(SRC_DIR)/validate/Makefile
	@echo "Verifying go module support: $$SRC_DIR outside of $$GOPATHs"
	for gopath in ${GOPATH//:/ }; do \
		test "$${SRC_DIR##$$GOPATH}" == "$$SRC_DIR"; \
	done
	@touch .pathok

.PHONY: .all_commited
.all_commited: .gofmt
	@echo "Verifying all repository changes have been commited"
	git diff --exit-code
	git diff --cached --exit-code

.PHONY: .commits_clean
.commits_clean: .all_commited
	@echo "Verifying whitespace errors and conflict markers"
	test -z "$(shell git diff --check $(ANCESTOR_BRANCH_COMMIT)..HEAD)"

.PHONY: .gofmt
.gofmt: .pathok
	@echo "Verifying no files are in need of gofmt."
	test -z "$(shell find . -name '*.go' ! -path './vendor/*' -exec gofmt -e -s -l {} \+)"

.PHONY: format
format:
	find . -name '*.go' ! -path './vendor/*' -exec gofmt -e -s -w {} \+

verify: .pathok .all_commited .commits_clean .gofmt
	@touch verify

validate.test: .pathok .gofmt
	go test -c

# ref: https://github.com/alecthomas/gometalinter
lint: .pathok .gofmt validate.test
	gometalinter \
		--line-length=140 --misspell-locale=en.US --tests --aggregate --enable-gc \
		--disable=megacheck \
		--disable=gochecknoinits \
		--disable=unparam \
		--disable=varcheck \
		--disable=structcheck \
		--exclude='validate_test.go.+file is not goimported' \
		--exclude='test_utils.go.+is unused' \
		--exclude='cannot find package' \
		--exclude='errors while loading package github.com:' \
		--exclude='gOOGLE_PROJECT_ID.+should be' \
		--exclude='gOOGLE_APPLICATION_CREDENTIALS.+should be' \
		--exclude='underscores.+GOOGLE_APPLICATION_CREDENTIALS' \
		--exclude='underscores.+GOOGLE_PROJECT_ID' \
		./...
	@touch lint

smoke: verify
	bash smoke.sh
	@touch smoke

../secrets/test-backend.auto.tfvars:
	$(MAKE) -C ../secrets ENV_NAME=test

PHONY: validate
validate: .pathok .gofmt ../secrets/test-backend.auto.tfvars validate.test
	env \
		GOOGLE_APPLICATION_CREDENTIALS="$(shell awk -F \" -e '/credentials = "/{print $$2}' ../secrets/test-backend.auto.tfvars)" \
		GOOGLE_PROJECT_ID="$(shell awk -F \" -e '/project = "/{print $$2}' ../secrets/test-backend.auto.tfvars)" \
		./validate.test \
			$(shell test $(TESTVERBOSE) -eq 0 || echo "-test.v") \
			-test.parallel=1 \
			-godog.random=$(SEED) \
			-godog.strict \
			-godog.format=progress \
			-godog.concurrency=4
