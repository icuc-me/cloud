
.PHONY: all
all: apply

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

.PHONY: prepare
prepare: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars
	@bin/prepare.sh $(ENV_NAME)-backend.auto.tfvars

.PHONY: apply
apply: guard-ENV_NAME plan $(ENV_NAME)-backend.auto.tfvars $(ENV_NAME)-uuid.auto.tfvars provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve plan

plan: guard-ENV_NAME init $(ENV_NAME)-backend.auto.tfvars $(ENV_NAME)-uuid.auto.tfvars provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform plan -input=false -var env_name=$(ENV_NAME) -out=$@

.terraform: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars prepare
	TF_IN_AUTOMATION=1 terraform init -input=false \
		-backend-config="$(ENV_NAME)-backend.auto.tfvars" \
		-force-copy -upgrade=true

$(ENV_NAME)-backend.auto.tfvars:
	ln -sf ../secrets/$(ENV_NAME)-backend.auto.tfvars

provider.auto.tfvars:
	ln -sf ../secrets/provider.auto.tfvars .

$(ENV_NAME)-uuid.auto.tfvars:
	ln -sf ../secrets/$(ENV_NAME)-uuid.auto.tfvars .

.PHONY: init
init: .terraform

.PHONY: teardown
teardown: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to teardown prod state."; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		bin/teardown.sh $(ENV_NAME)-backend.auto.tfvars || true; \
	fi

.PHONY: destroy
destroy: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars $(ENV_NAME)-uuid.auto.tfvars provider.auto.tfvars init
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
	elif [[ -n "$(ENV_NAME)" ]]; then \
		TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve -var env_name=$(ENV_NAME) || true; \
	fi;

.PHONY: clean
clean:
	-rm -f plan ./*tfstate* ./*-*.auto.tfvars
	-rm -rf .terraform
