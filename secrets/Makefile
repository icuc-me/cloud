

UUID_TOKEN=\%\%UUID\%\%
TEST_UUID=test$(shell uuidgen | tr -d -)
PROD_UUID=prod5808eee9756c49299496a99db62bdd7f
STAGE_UUID=stage85985f738ea84c4c8faccb1f4ee47327
ENV_NAME_TOKEN=\%\%ENV_NAME\%\%
CREDS_DIRPATH_TOKEN=\%\%CREDS_DIRPATH\%\%

.PHONY: all
all: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars uuid.auto.tfvars
	rm -f *backend.auto.tfvars.in_*
	rm -f .uuid

clean:
	rm -f *backend.auto.tfvars.in_*
	rm -f *backend.auto.tfvars
	rm -f uuid.auto.tfvars
	rm -f .uuid

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

.uuid: guard-ENV_NAME
	@if [[ "$(ENV_NAME)" =~ "test" ]]; then \
		echo "$(TEST_UUID)" > .uuid; \
	elif [[ "$(ENV_NAME)" =~ "stage" ]]; then \
		echo "$(STAGE_UUID)" > .uuid; \
	elif [[ "$(ENV_NAME)" =~ "prod" ]]; then \
		echo "$(PROD_UUID)" > .uuid; \
	else \
		echo "unknown$(shell uuidgen | tr -d -)" > .uuid; \
	fi

uuid.auto.tfvars: .uuid
	@echo "env_uuid = '$(shell cat .uuid)'" > uuid.auto.tfvars

$(ENV_NAME)-backend.auto.tfvars.in_2: all-backend.auto.tfvars.in .uuid
	sed -r -e 's/$(UUID_TOKEN)/$(shell cat "./.uuid")/g' '$<' > '$@'; \

$(ENV_NAME)-backend.auto.tfvars.in_3: $(ENV_NAME)-backend.auto.tfvars.in_2
	sed -r -e 's/$(ENV_NAME_TOKEN)/$(ENV_NAME)/g' '$<' > '$@'; \

$(ENV_NAME)-backend.auto.tfvars: $(ENV_NAME)-backend.auto.tfvars.in_3
	sed -r -e 's)$(CREDS_DIRPATH_TOKEN))$(shell realpath $(@D)))g' '$<' > '$@'
