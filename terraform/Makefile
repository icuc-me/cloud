
SRC_DIR=$(shell realpath "$$PWD/../")
SECRETS_DIR=$(SRC_DIR)/secrets
TERRAFORM_DIR=$(SRC_DIR)/terraform

.PHONY: all
all: apply

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
	bash $(SRC_DIR)/bin/prepare.sh "$(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars"

.PHONY: init
init: guard-ENV_NAME $(ENV_NAME)/.terraform/terraform.tfstate
$(ENV_NAME)/.terraform/terraform.tfstate: guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars prepare
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform init -input=false \
			-backend-config="backend.auto.tfvars" \
			-force-copy -upgrade=true

.PHONY: auto.tfvars
auto.tfvars: guard-SECRETS_DIR guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars $(ENV_NAME)/runtime.auto.tfvars

$(ENV_NAME)/plan: guard-ENV_NAME init auto.tfvars
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform plan -input=false -out=./plan

.PHONY: apply
apply: guard-ENV_NAME $(ENV_NAME)/plan auto.tfvars
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve ./plan

.PHONY: destroy
destroy: guard-ENV_NAME auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		cd "$(ENV_NAME)" && \
			( TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve || \
			  echo "Destroying $(ENV_NAME) resources failed, manual cleanup required"; \
			  exit 3; ) \
	fi

.PHONY: teardown
teardown: guard-ENV_NAME guard-SECRETS_DIR $(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to teardown prod state."; \
		exit 1; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		$(SRC_DIR)/bin/teardown.sh "$(SECRETS_DIR)/$(ENV_NAME)-backend.auto.tfvars" || \
		( echo "Tearing down backend for $(ENV_NAME) failed, you may have to clean it up manually"; \
		exit 2; ) \
	fi

.PHONY: clean
clean:
	# ALL environments
	-rm -fv {test,stage,prod}/plan
	-rm -fv {test,stage,prod}/*tfstate*
	-rm -fv {test,stage,prod}/{backend,runtime}.auto.tfvars
	-rm -rvf {test,stage,prod}/.terraform/*
