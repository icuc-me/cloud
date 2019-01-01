
.PHONY: all
all: apply

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

$(ENV_NAME)/%.auto.tfvars:
	cd "$(ENV_NAME)" && \
		ln -sf ../../secrets/$(ENV_NAME)-$*.auto.tfvars ./$*.auto.tfvars

.PHONY: prepare
prepare: guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars
	@bin/prepare.sh $(ENV_NAME)/backend.auto.tfvars

.PHONY: init
init: guard-ENV_NAME $(ENV_NAME)/.terraform
$(ENV_NAME)/.terraform: guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars prepare
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform init -input=false \
			-backend-config="backend.auto.tfvars" \
			-force-copy -upgrade=true

$(ENV_NAME)/runtime.auto.tfvars: guard-ENV_NAME guard-SRC_VERSION
	@echo 'env_name = "$(ENV_NAME)"' > "$@"
	@echo 'src_version = "$(SRC_VERSION)"' >> "$@"

.PHONY: auto.tfvars
auto.tfvars: $(ENV_NAME)/backend.auto.tfvars $(ENV_NAME)/uuid.auto.tfvars $(ENV_NAME)/provider.auto.tfvars $(ENV_NAME)/runtime.auto.tfvars

$(ENV_NAME)/plan: guard-ENV_NAME init auto.tfvars
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform plan -input=false -out=./plan

.PHONY: apply
apply: guard-ENV_NAME $(ENV_NAME)/plan auto.tfvars
	@cd "$(ENV_NAME)" && \
		TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve ./plan

.PHONY: teardown
teardown: guard-ENV_NAME $(ENV_NAME)/backend.auto.tfvars $(ENV_NAME)/uuid.auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to teardown prod state."; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		bin/teardown.sh $(ENV_NAME)/backend.auto.tfvars || \
		echo "Tearing down backend for $(ENV_NAME) ($(shell cat $(ENV_NAME)/uuid.auto.tfvars)) failed, you will have to clean it up manually"; \
	fi

.PHONY: destroy
destroy: guard-ENV_NAME auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		cd "$(ENV_NAME)" && \
			( TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve || \
			  echo "Destroying $(ENV_NAME) resources failed, manual cleanup required"; ) \
	fi

.PHONY: clean
clean:
	# ALL environments
	-rm -f */plan */*tfstate* */{backend,provider,uuid}.auto.tfvars */runtime.auto.tfvars
	-for env_name in test stage prod; do \
		rm -rf "$$env_name/.terraform"; \
	done
