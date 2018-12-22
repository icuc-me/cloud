ENV_NAME_TOKEN=\%\%ENV_NAME\%\%
CWD_TOKEN=\%\%CWD_PATH\%\%

.PHONY: all
all: guard-ENV_NAME backend.auto.tfvars

backend.auto.tfvars: backend.auto.tfvars.in_2
	sed -r -e 's)$(CWD_TOKEN))$(shell realpath $(@D)))g' '$^' > '$@'

backend.auto.tfvars.in_2: backend.auto.tfvars.in
	sed -r -e 's/$(ENV_NAME_TOKEN)/$(ENV_NAME)/g' '$^' > '$@'

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
		echo "Missing required make parameter '$*'."; \
		exit 1; \
	fi;

clean:
	rm -f backend.auto.tfvars.in_2
	rm -f backend.auto.tfvars
