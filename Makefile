ENV_FILE ?= .env
RESTART_WAIT_SEC ?= 30

-include $(ENV_FILE)
export IDRAC_IP IDRAC_USER IDRAC_PASS IDRAC_TARBALL

# Shared compose invocation; $(COMPOSE) is racadm with iDRAC connection flags.
DC := docker compose --env-file $(ENV_FILE)
COMPOSE := $(DC) run --rm racadm racadm --nocertwarn -r "$(IDRAC_IP)" -u "$(IDRAC_USER)" -p "$(IDRAC_PASS)"

.PHONY: help build status info sysinfo inventory version sel
.PHONY: power-on power-off restart power-cycle hard-reset
.PHONY: idrac-reset idrac-info cmd

help: ## Show available commands
	@echo "Dell PowerEdge server management via iDRAC7 (RACADM)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Custom command:  make cmd CMD=\"<racadm_args>\""
	@echo "Custom env file: make <target> ENV_FILE=.env.other"

build: ## Build racadm:latest image
	$(DC) build racadm

status: ## Server power status
	$(COMPOSE) serveraction powerstatus

info: ## System summary (getsysinfo)
	$(COMPOSE) getsysinfo

sysinfo: info ## Alias for info

inventory: ## Hardware inventory
	$(COMPOSE) hwinventory

version: ## RACADM / component versions
	$(COMPOSE) getversion

sel: ## System Event Log
	$(COMPOSE) getsel

power-on: ## Power on the server
	$(COMPOSE) serveraction powerup

power-off: ## Graceful shutdown
	$(COMPOSE) serveraction graceshutdown

restart: ## Graceful restart (shutdown + power on)
	$(COMPOSE) serveraction graceshutdown
	@echo "Waiting for shutdown ($(RESTART_WAIT_SEC)s)..."
	@sleep $(RESTART_WAIT_SEC)
	$(COMPOSE) serveraction powerup

power-cycle: ## Power cycle (hard cut + power on)
	$(COMPOSE) serveraction powercycle

hard-reset: ## Hard reset (forced reboot)
	$(COMPOSE) serveraction hardreset

idrac-reset: ## iDRAC soft reset (brief disconnect)
	$(COMPOSE) racreset soft

idrac-info: ## iDRAC network configuration
	$(COMPOSE) getniccfg

cmd: ## Run any RACADM command (make cmd CMD="...")
	$(COMPOSE) $(CMD)
