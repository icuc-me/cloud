

.PHONY: all
all: prep apply

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

.PHONY: prep
prep: guard-ENV_NAME ../bin/prep.sh $(ENV_NAME)-backend.auto.tfvars
	../bin/prep.sh $(ENV_NAME)-backend.auto.tfvars

.PHONY: apply
apply: guard-ENV_NAME plan
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve plan

plan: guard-ENV_NAME init provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform plan -input=false -var env_name=$(ENV_NAME) -out=$@

.terraform: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars provider.auto.tfvars
	@rm -f *-*.auto.tfvars
	@ln -sf ../secrets/$(ENV_NAME)-*.auto.tfvars ./
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

.PHONY: clean
clean: guard-ENV_NAME
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment" && exit 1; fi
	TF_IN_AUTOMATION=1 terraform destroy -auto-approve -var env_name=$(ENV_NAME)
	rm -f plan *tfstate* *-*.auto.tfvars
	rm -rf .terraform
