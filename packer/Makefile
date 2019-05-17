# Assumed to be used from quay.io/r4z0r7o3/tools.cloud.icuc.me:latest

SRC_DIR=$(shell realpath "$$PWD/../")
SECRETS_DIR=$(SRC_DIR)/secrets

# For debugging nested-virt, use
#TTYDEV := $(shell tty)
TTYDEV := /dev/null

_PHASE=phase_$(PHASE)

.PHONY: all
all: guard-PHASE $(_PHASE)-manifest.json

# Utility target for checking required parameters
.PHONY: guard-%
guard-%:
	@if [[ -z "$($*)" ]]; then \
        echo "Missing required make parameter '$*'."; \
        exit 1; \
    fi;

%.json: %.yml
	@python3 -c 'import json,yaml; json.dump( yaml.safe_load(open("$<").read()), open("$@","w"), indent=2);'

.PHONY: secrets
secrets: guard-GCP_ACCOUNT_FILE guard-GCP_PROJECT_ID guard-GCP_SERVICE_ACCOUNT_NAME guard-GCE_ZONE

cidata.ssh:
	ssh-keygen -f $@ -P "" -q

cidata.ssh.pub: cidata.ssh
	touch $@

meta-data:
	echo "local-hostname: localhost.localdomain" > $@

user-data: cidata.ssh.pub
	bash make-user-data.sh

cidata.iso: user-data meta-data
	genisoimage -output cidata.iso -volid cidata -input-charset utf-8 -joliet -rock user-data meta-data

.PHONY: test
test: guard-PHASE $(_PHASE).json
	packer inspect $(_PHASE).json

$(_PHASE)-manifest.json: guard-PHASE guard-TTYDEV secrets $(_PHASE).json test
	packer build \
		-var TTYDEV=$(TTYDEV) \
		-var GCP_ACCOUNT_FILE=$(GCP_ACCOUNT_FILE) \
		-var GCP_PROJECT_ID=$(GCP_PROJECT_ID) \
		-var GCP_SERVICE_ACCOUNT_NAME=$(GCP_SERVICE_ACCOUNT_NAME) \
		-var GCE_ZONE=$(GCE_ZONE) \
		$(_PHASE).json
