S_PHASE=1
N_PHASES=5
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

$(SECRETS_DIR)/$(ENV_NAME)-%.auto.tfvars: guard-SECRETS_DIR guard-ENV_NAME
	$(MAKE) -C "$(SECRETS_DIR)" ENV_NAME=$(ENV_NAME)

$(ENV_NAME)/%.auto.tfvars: $(SECRETS_DIR)/$(ENV_NAME)-%.auto.tfvars
	ln -sf "$^" "$(TERRAFORM_DIR)/$@"

.PHONY: prepare
prepare: guard-ENV_NAME guard-SECRETS_DIR $(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars
	test "$(ENV_NAME)" == "prod" || \
		bash $(SRC_DIR)/bin/prepare.sh "$(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars"

.PHONY: auto.tfvars
auto.tfvars: guard-SECRETS_DIR guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars $(ENV_NAME)/runtime.auto.tfvars

$(ENV_NAME)/n_phases: guard-ENV_NAME guard-N_PHASES
	echo "$(N_PHASES)" > "$@"

.PHONY: deploy
deploy: auto.tfvars $(ENV_NAME)/n_phases
	@for phase in $$(seq $(S_PHASE) $(N_PHASES)); \
	do \
		echo -e "\e[1;36;41m############################################################\e[0m"; \
		echo "                      Deploy phase $$phase of $(N_PHASES)"; \
		echo -e "\e[1;36;41m############################################################\e[0m"; \
		$(MAKE) -C $(ENV_NAME) PHASE=$$phase || exit 29; \
	done;

.PHONY: destroy
destroy: guard-ENV_NAME auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
		exit 1; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		for phase in $$(seq $(N_PHASES) -1 1); \
		do \
			echo -e "############################################################"; \
			echo -e "                      \e[1;36;41mDestroy phase $$phase\e[0m"; \
			echo -e "############################################################"; \
			$(MAKE) -C $(ENV_NAME) destroy PHASE=$$phase || true; \
		done; \
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
		$(MAKE) -C $$env_name clean; \
		rm -f $$env_name/*.auto.tfvars $$env_name/n_phases; done
