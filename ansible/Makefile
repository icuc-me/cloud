
.PHONY: all
all: guard-ENV_NAME
	ansible-playbook \
		--inventory ./environments/$(ENV_NAME) \
		--extra-vars=env_name=$(ENV_NAME) \
		--extra-vars=@../secrets/secrets.yml \
		main.yml

# Utility target for checking required parameters
guard-%:
	@if [[ -z "$($*)" ]]; then \
        echo "Missing required make parameter '$*'."; \
        exit 1; \
    fi;
