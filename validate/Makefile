

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

GOPATH=$(shell realpath $(shell go env GOPATH))
GOBIN=$(shell realpath $(shell go env GOBIN))
PROJECT=github.com/icuc-me/cloud/validate
SRC_DIR=$(shell realpath "../")
# TODO: OVERIDE this from value provided by CI system
ANCESTOR_BRANCH_COMMIT?=$(shell git merge-base origin/master HEAD)

.PHONY: clean
clean:
	rm -f .pathok verify lint smoke validate

.pathok: $(SRC_DIR)/validate/Makefile
	@echo "Verifying go module support: $$SRC_DIR outside of $$GOPATH"
	test "$${SRC_DIR##$$GOPATH}" == "$$SRC_DIR"
	@touch .pathok

.PHONY: .all_commited
.all_commited: .gofmt
	@echo "Verifying all repository changes have been commited"
	git diff --exit-code &> /dev/null
	git diff --cached --exit-code &> /dev/null

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

# ref: https://github.com/alecthomas/gometalinter
lint: .pathok .gofmt
	gometalinter ./...
	@touch lint

smoke: verify lint
	bash smoke.sh
	@touch smoke

PHONY: validate
validate: verify lint
	@echo "TODO: WRITE VALIDATION CHECKS"
	touch validate
