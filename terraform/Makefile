.PHONY: all
all: apply
	rm -f plan

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

.PHONY: apply
apply: guard-ENV_NAME plan
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve -var env_name=$(ENV_NAME) $<

plan: guard-ENV_NAME init provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform plan -input=false -var env_name=$(ENV_NAME) out=$@

.PHONY: init
init: backend.auto.tfvars
	TF_IN_AUTOMATION=1 terraform init -input=false -backend-config="$<" -force-copy -upgrade=true

.PHONY: clean
clean: guard-ENV_NAME init
	@if [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "Cowardly refusing to destroy prod environment"; \
		exit 1; \
	fi;
	TF_IN_AUTOMATION=1 terraform destroy -auto-approve -var env_name=$(ENV_NAME)
	rm -f plan
