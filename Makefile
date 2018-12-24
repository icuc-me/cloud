
.PHONY: all
all: help

.PHONY: help
help:
	@echo '###########################################################################'
	@echo 'Valid Make Targets:'
	@echo ''
	@echo 'test_env - Deploy to test environment'
	@echo 'stage_env - Deploy to staging environment'
	@echo 'prod_env - Deploy to production environment'
	@echo 'image_name - Return the canonical name for current runtime container image'
	@echo "version - Return the canonical version number for repo's current state"
	@echo ''
	@echo 'clean - remove temporary and generated files'
	@echo 'clean-test - Destroy test environment'
	@echo 'clean-stage - Destroy staging environment'
	@echo 'clean-prod - Reminder of your intelligence level'
	@echo ''
	@echo '###########################################################################'

.PHONY: version
version:
	@echo "$(shell git describe --abbrev=4 HEAD 2> /dev/null || echo '0.0.0')"

RUNTIME_IMAGE_REGISTRY ?= "quay.io"
RUNTIME_IMAGE_NAMESPACE ?= "r4z0r7o3"
RUNTIME_IMAGE_NAME ?= "runtime.cloud.icuc.me"
RUNTIME_IMAGE_TAG = "$(shell $(MAKE) version)"
.PHONY: image_name
image_name:
	@echo "$(RUNTIME_IMAGE_REGISTRY)/$(RUNTIME_IMAGE_NAMESPACE)/$(RUNTIME_IMAGE_NAME):$(RUNTIME_IMAGE_TAG)"

.PHONY: clean
clean:
	@$(MAKE) -C terraform clean
	@$(MAKE) -C secrets clean

.PHONY: clean-prod
clean-prod:
	$(error "I have a bag of hammers smarter than you")

.PHONY: clean-%
clean-%:
	@$(MAKE) -C secrets ENV_NAME=$*
	@$(MAKE) -C terraform clean ENV_NAME=$*
	@$(MAKE) -C terraform clean
	@$(MAKE) clean

.PHONY: %_env
%_env:
	@$(MAKE) -C secrets ENV_NAME=$*
	@$(MAKE) -C terraform ENV_NAME=$*
