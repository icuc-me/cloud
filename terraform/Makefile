
SRC_DIR=$(shell realpath "$$PWD/../")
SECRETS_DIR=$(SRC_DIR)/secrets
TERRAFORM_DIR=$(SRC_DIR)/terraform
EXTRA_ARGS ?=

.PHONY: all
all: prepare deploy

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

$(SECRETS_DIR)/$(ENV_NAME)-%.auto.tfvars: guard-SECRETS_DIR guard-ENV_NAME guard-SRC_VERSION
	$(MAKE) -C "$(SECRETS_DIR)" ENV_NAME=$(ENV_NAME) SRC_VERSION=$(SRC_VERSION)

$(ENV_NAME)/%.auto.tfvars: $(SECRETS_DIR)/$(ENV_NAME)-%.auto.tfvars
	ln -sf "$^" "$(TERRAFORM_DIR)/$@"

.PHONY: prepare
prepare: guard-ENV_NAME guard-SECRETS_DIR $(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars
	bash $(SRC_DIR)/bin/prepare.sh "$(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars"

.PHONY: auto.tfvars
auto.tfvars: guard-SECRETS_DIR guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars $(ENV_NAME)/runtime.auto.tfvars

deploy: auto.tfvars
	$(MAKE) -C $(ENV_NAME)

.PHONY: destroy
destroy: guard-ENV_NAME auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
		exit 1; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		$(MAKE) -C $(ENV_NAME) destroy \
			|| true; \
	fi

.PHONY: teardown
teardown: guard-ENV_NAME guard-SECRETS_DIR $(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to teardown prod state."; \
		exit 1; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		bash $(SRC_DIR)/bin/teardown.sh "$(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars" \
			|| true; \
	fi

.PHONY: clean
clean:
	-for env_name in test stage prod; do \
		$(MAKE) -C $$env_name clean; done
