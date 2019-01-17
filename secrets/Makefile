
SRC_DIR=$(shell realpath "$$PWD/../")
TEST_UUID=test-$(shell uuidgen | cut -d - -f 1,4 | tr -d -)
STAGE_UUID=stage-6f0ea558b32c
PROD_UUID=prod-89db7eecb49d

.PHONY: all
all: guard-ENV_NAME $(ENV_NAME)-uuid $(ENV_NAME)-backend.auto.tfvars $(ENV_NAME)-runtime.auto.tfvars

clean:
	rm -fv *.auto.tfvars
	rm -fv *-uuid

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

%-uuid: guard-ENV_NAME
	[[ -r "$(ENV_NAME)-uuid" ]] && [[ "$*" == "test" ]] || echo "$(TEST_UUID)" > test-uuid
	[[ -r "$(ENV_NAME)-uuid" ]] && [[ "$*" == "stage" ]] || echo "$(STAGE_UUID)" > stage-uuid
	[[ -r "$(ENV_NAME)-uuid" ]] && [[ "$*" == "prod" ]] || echo "$(PROD_UUID)" > prod-uuid
	touch "$@"

test-%.auto.tfvars: test-uuid
	@[[ -r "$@" ]] || bash $(SRC_DIR)/bin/secrets.sh test
	touch "$@"

stage-%.auto.tfvars: stage-uuid test-uuid
	@[[ -r "$@" ]] || bash $(SRC_DIR)/bin/secrets.sh stage test
	touch "$@"

prod-%.auto.tfvars: prod-uuid stage-uuid test-uuid
	@[[ -r "$@" ]] || bash $(SRC_DIR)/bin/secrets.sh prod stage test
	touch "$@"

$(ENV_NAME)-runtime.auto.tfvars: guard-ENV_NAME $(ENV_NAME)-backend.auto.tfvars
