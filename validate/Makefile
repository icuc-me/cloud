
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

GOPATH=$(shell go env GOPATH)
GOBIN=$(shell go env GOBIN)
PROJECT=github.com/icuc-me/cloud/validate
SRC_DIR=$(shell realpath "../")
ENV_NAME?=test
TF_CFG_DIR?=$(SRC_DIR)/terraform/$(ENV_NAME)
ANCESTOR_BRANCH_COMMIT?=$(shell git merge-base origin/master HEAD)
SEED=$(shell date +%s)

VERBOSE?=0
ifeq ($(VERBOSE),0)
GODOGARGS=-godog.format=progress -godog.concurrency=4
else
GODOGARGS=-test.v -godog.format=pretty -godog.concurrency=1
endif

.PHONY: clean
clean:
	rm -f .pathok verify lint smoke validate.test

.pathok: $(SRC_DIR)/validate/Makefile
	@echo "Verifying go module support: $$SRC_DIR outside of $$GOPATHs"
	for gopath in $${GOPATH//:/ }; do \
		test "$${SRC_DIR##$$GOPATH}" == "$$SRC_DIR"; \
	done
	test -n "$(GOPATH)"
	test -n "$$GOPATH"
	test -n "$$PATH"
	@echo "Verifying \$${GOPATH}/bin exists in \$${PATH}"
	@echo "PATH=$$PATH"
	@echo "GOPATH=$$GOPATH"
	echo "$$PATH" | grep -q "$$GOPATH/bin"
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

# ref: https://github.com/golangci/golangci-lint#quick-start
lint: .pathok .gofmt validate.test
	golangci-lint run --tests ./...
	@touch lint

smoke: verify
	bash smoke.sh $(ENV_NAME)
	@touch smoke

../secrets/$(ENV_NAME)-backend.auto.tfvars:
	$(MAKE) -C ../secrets ENV_NAME=$(ENV_NAME)

PHONY: validate
validate: .pathok .gofmt ../secrets/$(ENV_NAME)-backend.auto.tfvars validate.test
	env \
		GOOGLE_APPLICATION_CREDENTIALS="$(shell awk -F \" -e '/credentials = "/{print $$2}' ../secrets/$(ENV_NAME)-backend.auto.tfvars)" \
		GOOGLE_PROJECT_ID="$(shell awk -F \" -e '/project = "/{print $$2}' ../secrets/$(ENV_NAME)-backend.auto.tfvars)" \
		TF_CFG_DIR=$(TF_CFG_DIR) \
		ENV_NAME=$(ENV_NAME) \
		./validate.test \
			-test.parallel=1 \
			-godog.random=$(SEED) \
			$(GODOGARGS)
