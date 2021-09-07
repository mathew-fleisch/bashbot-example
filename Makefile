CFLAGS=-g
export CFLAGS

LOG_LEVEL?=info
LOG_FORMAT?=text

.PHONY: install-latest run-binary int-run-binary docker-build-alpine docker-build-ubuntu docker-run docker-run-local docker-exec config-maps get delete describe exec logs
# --------------- Run With Release Binary --------------- #

os=$(shell uname | tr '[:upper:]' '[:lower:]')
ifeq ($(shell uname -m),aarch64)
	arch?="arm64"
else
	arch?="amd64"
endif
latest=$(shell curl -s https://api.github.com/repos/mathew-fleisch/bashbot/releases/latest | grep tag_name | cut -d '"' -f 4)

install-latest:
	@rm -rf /usr/local/bin/bashbot || true
	@echo "Get latest version: $(latest)"
	@wget -qO /usr/local/bin/bashbot https://github.com/mathew-fleisch/bashbot/releases/download/$(latest)/bashbot-$(os)-$(arch)
	@chmod +x /usr/local/bin/bashbot
	@echo "Bashbot binary $(latest) downloaded to /usr/local/bin/bashbot"
	@echo "For help, run 'bashbot --help'"
	bashbot --version
	bashbot --help

# This bash/trap workaround is needed to clean up the dependencies bashbot depends on, after it is done running
run-binary:
	bash -c "trap 'trap - SIGINT SIGTERM ERR; rm -rf vendor || true; exit 1' SIGINT SIGTERM ERR; $(MAKE) int-run-binary"


int-run-binary:
	@expected="SLACK_TOKEN BASHBOT_CONFIG_FILEPATH" /bin/bash scripts/check-environment-variables.sh
	@mkdir -p vendor && cd vendor
	@bashbot --install-vendor-dependencies
	@cd ..
	@bashbot

# --------------- Run Locally With Docker --------------- #

docker-run:
	@expected="SLACK_TOKEN BASHBOT_CONFIG_FILEPATH" /bin/bash scripts/check-environment-variables.sh
	@docker run --rm \
		-v $(BASHBOT_CONFIG_FILEPATH):/bashbot/config.json \
		-e BASHBOT_CONFIG_FILEPATH="/bashbot/config.json" \
		-e SLACK_TOKEN=$(SLACK_TOKEN) \
		-e LOG_LEVEL="$(LOG_LEVEL)" \
		-e LOG_FORMAT="$(LOG_FORMAT)" \
		--name bashbot \
		-it mathewfleisch/bashbot:latest

docker-build-alpine:
	@docker build -t bashbot-local -f Dockerfile.alpine	.

docker-build-ubuntu:
	@docker build -t bashbot-local -f Dockerfile.ubuntu	.

docker-run-local:
	@expected="SLACK_TOKEN BASHBOT_CONFIG_FILEPATH" /bin/bash scripts/check-environment-variables.sh
	@docker run --rm \
		-v $(BASHBOT_CONFIG_FILEPATH):/bashbot/config.json \
		-e BASHBOT_CONFIG_FILEPATH="/bashbot/config.json" \
		-e SLACK_TOKEN=$(SLACK_TOKEN) \
		-e LOG_LEVEL="$(LOG_LEVEL)" \
		-e LOG_FORMAT="$(LOG_FORMAT)" \
		--name bashbot \
		-it bashbot-local:latest

docker-exec:
	@expected="SLACK_TOKEN BASHBOT_CONFIG_FILEPATH" /bin/bash scripts/check-environment-variables.sh
	@docker exec -it $(shell docker ps -aqf "name=bashbot") bash

# --------------- Kubernetes Stuff --------------- #
NAMESPACE?=bashbot


config-maps:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	@echo "Updating configmaps for: $(bot_name)"
	@./scripts/config-maps.sh $(bot_name) $(NAMESPACE)

get:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	kubectl -n $(NAMESPACE) get pod -l "app=$(bot_name)" --output=jsonpath={.items..metadata.name}

delete:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	kubectl -n $(NAMESPACE) delete pod $(shell kubectl -n $(NAMESPACE) get pod -l "app=$(bot_name)" --output=jsonpath={.items..metadata.name})

describe:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	kubectl -n $(NAMESPACE) describe pod $(shell kubectl -n $(NAMESPACE) get pod -l "app=$(bot_name)" --output=jsonpath={.items..metadata.name})

exec:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	kubectl -n $(NAMESPACE) exec -it $(shell kubectl -n $(NAMESPACE) get pod -l "app=$(bot_name)" --output=jsonpath={.items..metadata.name}) -- bash

logs:
	@export NAMESPACE=$(NAMESPACE) && expected="bot_name NAMESPACE" /bin/bash scripts/check-environment-variables.sh
	kubectl -n $(NAMESPACE) logs -f $(shell kubectl -n $(NAMESPACE) get pod -l "app=$(bot_name)" --output=jsonpath={.items..metadata.name})

