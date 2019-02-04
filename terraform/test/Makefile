
MODULES=$(shell ls -1 ./modules/*/*.tf)
CFG=$(shell ls -1 *.tf)

.PHONY: all
all: init validate preload plan apply

init: backend.auto.tfvars $(MODULES)
	TF_IN_AUTOMATION=1 terraform init -input=false -backend-config="./backend.auto.tfvars" "./" \
		| tee $@
	rm -f validate preload plan apply

validate: runtime.auto.tfvars $(CFG)
	TF_IN_AUTOMATION=1 terraform validate "./" \
		| tee $@
	rm -f preload plan apply

preload: validate
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve -target=null_resource.preload "./" \
		| tee $@
	rm -f plan apply

plan: preload
	TF_IN_AUTOMATION=1 terraform plan -input=false -module-depth=0 "-out=./plan" "./"
	rm -f apply

apply: plan
	-@read -t 10 -p "PAUSING: Press enter or wait 10 seconds to continue. Ctrl-c to abort."
	TF_IN_AUTOMATION=1 terraform apply -input=false -auto-approve "./plan" \
		| tee $@

destroy: init validate preload
	-TF_IN_AUTOMATION=1 terraform destroy -input=false -auto-approve "./"

.PHONY: clean
clean:
	-rm -fv backend.auto.tfvars
	-rm -fv runtime.auto.tfvars
	-rm -f init validate preload plan apply
	-rm -rfv .terraform
