
.PHONY: all
all:
	terraform init -backend-config="terraform.secrets"
	terraform apply
