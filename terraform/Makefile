SETUP_BACKEND ?= 0

.PHONY: all
all: apply

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

.PHONY: apply
apply: guard-ENV_NAME plan
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve plan

plan: guard-ENV_NAME init provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform plan -input=false -var env_name=$(ENV_NAME) -out=$@

.terraform: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars provider.auto.tfvars
	@if (($(SETUP_BACKEND))) && [[ "$(ENV_NAME)" != "prod" ]]; then \
		rm -f terraform.tf; \
		TF_IN_AUTOMATION=1 terraform init -input=false -upgrade=true; \
		TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve \
			-var env_name=$(ENV_NAME) \
			-target=google_storage_bucket.terraform-state; \
		git checkout terraform.tf; \
	fi
	TF_IN_AUTOMATION=1 terraform init -input=false \
		-backend-config="$(ENV_NAME)-backend.auto.tfvars" \
		-force-copy -upgrade=true

$(ENV_NAME)-backend.auto.tfvars: guard-ENV_NAME ../secrets/$(ENV_NAME)-backend.auto.tfvars
	rm -f *backend.auto.tfvars
	ln -s ../secrets/$(ENV_NAME)-backend.auto.tfvars .

provider.auto.tfvars:
	ln -s ../secrets/provider.auto.tfvars .

uuid.auto.tfvars:
	ln -s ../secrets/uuid.auto.tfvars .

.PHONY: init
init: .terraform

.PHONY: clean
clean:
	@case "$(ENV_NAME)" in \
		prod) echo "Cowardly refusing to destroy prod environment" && exit 1 ;; \
		test) ;& \
		stage) TF_IN_AUTOMATION=1 terraform destroy -auto-approve -var env_name=$(ENV_NAME) ;; \
	esac
	rm -f plan *tfstate* *backend.auto.tfvars *provider.auto.tfvars *uuid.auto.tfvars
	rm -rf .terraform
