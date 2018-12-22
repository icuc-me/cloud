
.PHONY: all
all: help

.PHONY: help
help:
	@echo '###########################################################################'
	@echo 'Valid Make Targets:'
	@echo ''
	@echo 'test_env - Deploy to test environment'
	@echo 'stage_env - Deploy to staging environment'
	@echo 'prod_env - Deploy to production environment'
	@echo ''
	@echo 'clean - remove temporary and generated files'
	@echo 'clean-test - Destroy test environment'
	@echo 'clean-stage - Destroy staging environment'
	@echo 'clean-prod - Remind you of your intelligence level'
	@echo ''
	@echo '###########################################################################'

.PHONY: clean
clean:
	@$(MAKE) -C secrets clean

.PHONY: clean-prod
clean-prod:
	$(error "I have a bag of hammers smarter than you")

.PHONY: clean-%
clean-%: clean
	@$(MAKE) -C secrets ENV_NAME=$*
	@$(MAKE) -C terraform clean ENV_NAME=$*
	@$(MAKE) clean

.PHONY: %_env
%_env: clean
	@$(MAKE) -C secrets ENV_NAME=$*
	@$(MAKE) -C terraform ENV_NAME=$*
