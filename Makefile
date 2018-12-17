
.PHONY: all
all:
	terraform init -backend-config="backend.auto.tfvars"
	terraform apply
