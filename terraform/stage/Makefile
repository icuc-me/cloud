_PHASE=phase_$(PHASE)
_PLAN_TXT=$(_PHASE)/plan.output
SRCFILES=$(shell ls -1 $(_PHASE)*.tf common*.tf *.yml)
ENV_NAME=$(shell basename $$PWD)

all: guard-PHASE guard-ENV_NAME $(_PHASE)/apply

$(_PHASE): guard-PHASE guard-ENV_NAME backend.auto.tfvars
	mkdir -p "$@"
	@for src in ./modules/ *.auto.tfvars common_*.tf only_$(ENV_NAME)_*.tf $(_PHASE)_main.tf $(_PHASE)_$(ENV_NAME).tf; do \
		test ! -r "$$src" || ln -rsvft "$@" "$$src"; done
	TF_IN_AUTOMATION=1 terraform init -input=false -backend-config="./backend.auto.tfvars" "./$@"
	-TF_IN_AUTOMATION=1 terraform workspace new "$(_PHASE)"

$(_PHASE)/plan.bin: guard-PHASE $(_PHASE) runtime.auto.tfvars test-strongbox.yml stage-strongbox.yml prod-strongbox.yml $(SRCFILES)
	rm -f "$@" "$(_PLAN_TXT)"
	TF_IN_AUTOMATION=1 terraform workspace select "$(_PHASE)" "$(_PHASE)/"
	TF_IN_AUTOMATION=1 terraform validate "$(_PHASE)/"
	set -eo pipefail && TF_IN_AUTOMATION=1 terraform plan -input=false -module-depth=0 "-out=$@" "$(_PHASE)/" | tee "$(_PLAN_TXT)"

.PHONY: $(_PHASE)/apply
$(_PHASE)/apply: guard-PHASE $(_PHASE)/plan.bin $(SRCFILES)
	-@read -t 10 -p "$(_PHASE) Pause: press enter, wait 10 seconds to continue, or ctrl-c to abort."
	TF_LOG_PATH="$(_PHASE)/apply.log" TF_LOG=DEBUG TF_IN_AUTOMATION=1 \
				terraform apply -input=false -auto-approve "$(_PHASE)/plan.bin"

.PHONY: destroy
destroy: guard-PHASE $(_PHASE)/plan.bin $(SRCFILES)
	TF_IN_AUTOMATION=1 terraform workspace select "$(_PHASE)" "$(_PHASE)/"
	-TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve "$(_PHASE)/"

.PHONY: clean
clean:
	-rm -rfv phase_{1..99} .terraform

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;
