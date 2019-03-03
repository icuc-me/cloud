_PHASE=phase_$(PHASE)
_DOT_PHASE=.$(_PHASE)
_PLAN_TXT=$(_DOT_PHASE)/plan.output
SRCFILES=$(shell ls -1 $(_PHASE)*.tf common*.tf *.yml)

all: guard-PHASE $(_DOT_PHASE)/apply

$(_DOT_PHASE): guard-PHASE backend.auto.tfvars
	mkdir -p "$@"
	@for src in ./modules/ *.auto.tfvars common_*.tf $(_PHASE)_*.tf; do \
		ln -rsvft "$@" "$$src"; done
	TF_IN_AUTOMATION=1 terraform init -input=false -backend-config="./backend.auto.tfvars" "./$@"
	-TF_IN_AUTOMATION=1 terraform workspace new "$(_PHASE)"

$(_DOT_PHASE)/plan.bin: guard-PHASE $(_DOT_PHASE) runtime.auto.tfvars test-strongbox.yml stage-strongbox.yml prod-strongbox.yml $(SRCFILES)
	rm -f "$@" "$(_PLAN_TXT)"
	TF_IN_AUTOMATION=1 terraform workspace select "$(_PHASE)" "$(_DOT_PHASE)/"
	TF_IN_AUTOMATION=1 terraform validate "$(_DOT_PHASE)/"
	set -eo pipefail && TF_IN_AUTOMATION=1 terraform plan -input=false -module-depth=0 "-out=$@" "$(_DOT_PHASE)/" | tee "$(_PLAN_TXT)"

.PHONY: $(_DOT_PHASE)/apply
$(_DOT_PHASE)/apply: guard-PHASE $(_DOT_PHASE)/plan.bin $(SRCFILES)
	@if ! grep -q 'No changes. Infrastructure is up-to-date.' "$(_PLAN_TXT)"; then \
		read -t 10 -p "$(_PHASE) Pause: press enter, wait 10 seconds to continue, or ctrl-c to abort."; \
		TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve "$(_DOT_PHASE)/plan.bin"; \
	else \
		echo "Nothing to apply for $(_PHASE)"; \
	fi

.PHONY: destroy
destroy: guard-PHASE $(_DOT_PHASE) $(SRCFILES)
	TF_IN_AUTOMATION=1 terraform workspace select "$(_PHASE)" "$(_DOT_PHASE)/"
	-TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve "$(_DOT_PHASE)/"

.PHONY: clean
clean:
	-rm -rfv .phase_{1..99} .terraform

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;
