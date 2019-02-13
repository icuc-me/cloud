
.PHONY: all
all: help

.PHONY: help
help:
	@echo '###########################################################################'
	@echo 'Available Make Targets:'
	@echo '###########################################################################'
	@echo ''
	@echo 'test_env - Deploy to test environment'
	@echo 'stage_env - Deploy to staging environment'
	@echo 'prod_env - Deploy to production environment'
	@echo ''
	@echo 'test_clean - Destroy test environment'
	@echo 'stage_clean - Destroy staging environment'
	@echo 'prod_clean - Reminder intelligence level'
	@echo ''
	@echo 'validate - Execute automated source and test-environment validation'
	@echo "version - Return the canonical version number for repo's current state"
	@echo 'image_name - Return the canonical name for current runtime container image'
	@echo 'clean - remove temporary and generated files'
	@echo ''
	@echo 'N/B: Use of bin/make.sh for everything is assumed'
	@echo '###########################################################################'

VERCMD = git describe --abbrev=6 HEAD 2> /dev/null || echo 'TAG-REF-ERROR'
.PHONY: version
version:
	@echo "$(shell $(VERCMD))"

RUNTIME_IMAGE_REGISTRY ?= quay.io
RUNTIME_IMAGE_NAMESPACE ?= r4z0r7o3
RUNTIME_IMAGE_NAME ?= runtime.cloud.icuc.me
SRC_VERSION = $(shell $(VERCMD))
.PHONY: image_name
image_name:
	@echo "$(RUNTIME_IMAGE_REGISTRY)/$(RUNTIME_IMAGE_NAMESPACE)/$(RUNTIME_IMAGE_NAME):$(SRC_VERSION)"

.PHONY: validate
validate:
	@bash validate/runner.sh

.PHONY: %_env
%_env:
	@$(MAKE) -C terraform ENV_NAME=$* SRC_VERSION=$(SRC_VERSION)

.PHONY: clean
clean:
	$(MAKE) -C terraform clean
	$(MAKE) -C secrets clean
	$(MAKE) -C validate clean

.PHONY: prod_clean
clean_prod:
	$(error "I have a bag of hammers smarter than you")

.PHONY: _squeeky_%_clean
_squeeky_%_clean:
	@echo "WARNING: IRREVERSIBLY DESTROYING STATE OF $* ENVIRONMENT"
	@read -t 10 -p "press enter or wait 10 seconds to continue, ctrl-c to abort." || true
	$(MAKE) -C terraform teardown ENV_NAME=$* SRC_VERSION=$(SRC_VERSION);

.PHONY: %_clean
%_clean:
	@if $(MAKE) -C terraform destroy ENV_NAME=$* SRC_VERSION=$(SRC_VERSION); then \
		$(MAKE) _squeeky_$*_clean; \
	else \
		$(MAKE) _squeeky_$*_clean; \
		exit 1; \
	fi
