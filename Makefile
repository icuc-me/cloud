.PHONY: all
all: apply
	rm -f plan

.PHONY: apply
apply: plan
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve $<

plan: init provider.auto.tfvars
	TF_IN_AUTOMATION=1 terraform plan -input=false -out=$@

.PHONY: init
init: backend.auto.tfvars
	TF_IN_AUTOMATION=1 terraform init -input=false -backend-config="$<"
