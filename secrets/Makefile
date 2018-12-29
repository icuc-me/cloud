
UUID_TOKEN=\%\%UUID\%\%
TEST_UUID=test$(shell uuidgen | tr -d -)
PROD_UUID=prod5808eee9756c49299496a99db62bdd7f
STAGE_UUID=stage85985f738ea84c4c8faccb1f4ee47327
ENV_NAME_TOKEN=\%\%ENV_NAME\%\%
CREDS_DIRPATH_TOKEN=\%\%CREDS_DIRPATH\%\%
SUSERNAME=$(shell ls $(ENV_NAME)-*.json | cut -d - -f 2 | cut -d . -f 1)
SUSERNAME_TOKEN=\%\%SUSERNAME\%\%

.PHONY: all
all: guard-ENV_NAME uuid $(ENV_NAME)-uuid.auto.tfvars $(ENV_NAME)-backend.auto.tfvars provider.auto.tfvars $(ENV_NAME)-secrets.yml

.PHONY: Makefile

clean:
	rm -f *-secrets.yml
	rm -f *backend.auto.tfvars
	rm -f *-uuid.auto.tfvars
	rm -f *-uuid

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

$(ENV_NAME)-secrets.yml: guard-ENV_NAME guard-SUSERNAME $(ENV_NAME)-backend.auto.tfvars provider.auto.tfvars $(ENV_NAME)-uuid.auto.tfvars
	@echo "Producing $@"
	@./terraform_to_ansible.sh $(ENV_NAME) $(SUSERNAME) > $@
	@echo -e "\nterraform_project: \"$(shell realpath ../terraform)\"" >> $@

.PHONY: uuid
uuid: guard-ENV_NAME
	@echo "Producing $(ENV_NAME)-uuid"
	@[[ -r "$(ENV_NAME)-uuid" ]] || if [[ "$(ENV_NAME)" =~ "test" ]]; then \
		echo "$(TEST_UUID)" > $(ENV_NAME)-uuid; \
	elif [[ "$(ENV_NAME)" =~ "stage" ]]; then \
		echo "$(STAGE_UUID)" > $(ENV_NAME)-uuid; \
	elif [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "$(PROD_UUID)" > $(ENV_NAME)-uuid; \
	else \
		echo "unknown$(shell uuidgen | tr -d -)" > $(ENV_NAME)-uuid; \
	fi

$(ENV_NAME)-uuid.auto.tfvars: guard-ENV_NAME uuid
	@echo "Producing $@"
	@echo "env_uuid = \"$(shell cat $(ENV_NAME)-uuid)\"" > $@

$(ENV_NAME)-backend.auto.tfvars: all-backend.auto.tfvars.in $(ENV_NAME)-uuid.auto.tfvars uuid guard-ENV_NAME
	@echo "Producing $@"
	@sed -r -e 's)$(CREDS_DIRPATH_TOKEN))$(shell realpath $(@D)))g;s/$(UUID_TOKEN)/$(shell cat "./$(ENV_NAME)-uuid")/g;s/$(SUSERNAME_TOKEN)/$(SUSERNAME)/g;s/$(ENV_NAME_TOKEN)/$(ENV_NAME)/g;' '$<' > '$@'
