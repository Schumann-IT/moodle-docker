.PHONY: help build pull up up-fg down kill clean restart logs ps config exec-moodle exec-db exec-shell

COMPOSE ?= docker compose

ENV_FILE ?= .env
COMPOSE_ENV := $(if $(wildcard $(ENV_FILE)),--env-file $(ENV_FILE),)
COMPOSE_CMD := $(COMPOSE) $(COMPOSE_ENV)

DATA_MODE ?= volume
DATA_DIR ?= ./data

ifeq ($(DATA_MODE),bind)
  DBDATA_SOURCE ?= $(DATA_DIR)/dbdata
  MOODLEDATA_SOURCE ?= $(DATA_DIR)/moodledata
else
  DBDATA_SOURCE ?= dbdata
  MOODLEDATA_SOURCE ?= moodledata
endif

export DBDATA_SOURCE
export MOODLEDATA_SOURCE

help:
	@echo "Targets:"
	@echo "  build        Build images"
	@echo "  pull         Pull base images"
	@echo "  up           Start services in background"
	@echo "  up-fg        Start services in foreground"
	@echo "  down         Stop services (keeps data)"
	@echo "  kill         Stop services and remove volumes"
	@echo "  clean        Stop services, remove volumes, delete bind data dir, remove images (requires CLEAN_CONFIRM=1)"
	@echo "  restart      Restart services"
	@echo "  logs         Follow logs"
	@echo "  ps           Show container status"
	@echo "  config       Show rendered compose config"
	@echo "  exec-shell   Shell into moodle container"
	@echo "  exec-db      mysql client into db container"
	@echo "  exec-moodle  Run a command in moodle container (CMD='...')"
	@echo ""
	@echo "Options:"
	@echo "  DATA_MODE=volume|bind   (default: volume)"
	@echo "  DATA_DIR=./data         base dir for bind mounts"
	@echo "  DBDATA_SOURCE=...       override database data source"
	@echo "  MOODLEDATA_SOURCE=...   override moodledata source"

build:
	$(COMPOSE_CMD) build

pull:
	$(COMPOSE_CMD) pull

prepare-data:
	@if [ "$(DATA_MODE)" = "bind" ]; then \
		mkdir -p "$(DBDATA_SOURCE)" "$(MOODLEDATA_SOURCE)"; \
	fi

up-db: prepare-data
	$(COMPOSE_CMD) up -d db

up: prepare-data
	$(COMPOSE_CMD) up -d

up-fg: prepare-data
	$(COMPOSE_CMD) up

down:
	$(COMPOSE_CMD) down

kill:
	$(COMPOSE_CMD) down -v --remove-orphans

clean:
	$(COMPOSE_CMD) down -v --remove-orphans --rmi local
	rm -rf "$(DATA_DIR)"

restart:
	$(COMPOSE_CMD) restart

logs:
	$(COMPOSE_CMD) logs -f --tail=200

ps:
	$(COMPOSE_CMD) ps

config:
	$(COMPOSE_CMD) config

exec-shell:
	$(COMPOSE_CMD) exec moodle sh

exec-db:
	$(COMPOSE_CMD) exec db sh -lc 'mysql -u"$${MYSQL_USER}" -p"$${MYSQL_PASSWORD}" "$${MYSQL_DATABASE}"'

exec-moodle:
	@if [ -z "$(CMD)" ]; then \
		echo "Set CMD, e.g.: make exec-moodle CMD='php admin/cli/cron.php'"; \
		exit 1; \
	fi
	$(COMPOSE_CMD) exec moodle sh -lc "$(CMD)"
