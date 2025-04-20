.PHONY: help install server watch postgres postgres-rm psql

help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Run the initial setup
	mix setup

server: ## Start the web server
	iex -S mix phx.server

watch: ## Recompile on file changes
	find lib/ | entr mix compile

postgres: ## Start a container with latest postgres
	docker run --detach -e POSTGRES_PASSWORD="postgres" -p 15432:5432 --name algora_db --volume=algora_db:/var/lib/postgresql/data postgres:latest

postgres-rm: ## Stop and remove the postgres container
	docker stop algora_db && docker rm algora_db

psql: ## Connect to postgres
	docker exec -it algora_db psql -U postgres -d algora_dev