# Makefile for MedRAX Docker Management
# Provides convenient shortcuts for common Docker operations
# ============================================================================

.PHONY: help build start stop restart logs status shell clean setup all

# Default target
.DEFAULT_GOAL := help

# Configuration
INVOKE_SCRIPT := ./invoke.sh
COMPOSE_FILE := docker-compose.yml

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

## help: Display this help message
help:
	@echo "$(BLUE)MedRAX Docker Management$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC) make [target]"
	@echo ""
	@echo "$(GREEN)Targets:$(NC)"
	@grep -E '^## ' $(MAKEFILE_LIST) | \
		sed 's/^## //' | \
		awk 'BEGIN {FS = ":"}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make setup    # First time setup"
	@echo "  make start    # Start the container"
	@echo "  make logs     # View logs"
	@echo ""

## setup: First time setup - create .env and directories
setup:
	@echo "$(BLUE)Setting up MedRAX...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓$(NC) Created .env file from template"; \
		echo "$(YELLOW)⚠$(NC) Please edit .env and add your OPENAI_API_KEY"; \
	else \
		echo "$(YELLOW)⚠$(NC) .env file already exists"; \
	fi
	@mkdir -p temp logs model-weights
	@echo "$(GREEN)✓$(NC) Created directories: temp, logs, model-weights"
	@chmod +x $(INVOKE_SCRIPT)
	@echo "$(GREEN)✓$(NC) Made invoke.sh executable"
	@echo ""
	@echo "$(GREEN)Setup complete!$(NC) Next steps:"
	@echo "  1. Edit .env and set OPENAI_API_KEY"
	@echo "  2. Run: make build"
	@echo "  3. Run: make start"

## build: Build the Docker image
build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	@$(INVOKE_SCRIPT) build

## start: Start the container
start:
	@echo "$(BLUE)Starting MedRAX container...$(NC)"
	@$(INVOKE_SCRIPT) start

## stop: Stop the container
stop:
	@echo "$(BLUE)Stopping MedRAX container...$(NC)"
	@$(INVOKE_SCRIPT) stop

## restart: Restart the container
restart:
	@echo "$(BLUE)Restarting MedRAX container...$(NC)"
	@$(INVOKE_SCRIPT) restart

## logs: Show container logs (follow mode)
logs:
	@$(INVOKE_SCRIPT) logs

## status: Show container status
status:
	@$(INVOKE_SCRIPT) status

## shell: Open interactive shell in container
shell:
	@$(INVOKE_SCRIPT) shell

## clean: Stop container and remove temporary files
clean:
	@echo "$(BLUE)Cleaning up...$(NC)"
	@$(INVOKE_SCRIPT) cleanup
	@echo "$(GREEN)✓$(NC) Cleanup complete"

## deep-clean: Remove everything including images and volumes
deep-clean: clean
	@echo "$(BLUE)Performing deep clean...$(NC)"
	@docker rmi -f bowang-lab--medrax_image:latest 2>/dev/null || true
	@rm -rf temp logs
	@echo "$(GREEN)✓$(NC) Deep clean complete"

## compose-up: Start using docker-compose
compose-up:
	@echo "$(BLUE)Starting with docker-compose...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✓$(NC) Container started"
	@echo "$(GREEN)Access at:$(NC) http://localhost:11180"

## compose-down: Stop using docker-compose
compose-down:
	@echo "$(BLUE)Stopping docker-compose services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down

## compose-logs: Show docker-compose logs
compose-logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

## all: Complete setup and start (for first-time users)
all: setup build start status
	@echo ""
	@echo "$(GREEN)✓ MedRAX is ready!$(NC)"
	@echo "$(GREEN)Access at:$(NC) http://localhost:11180"

## dev: Start in development mode with source mounted
dev:
	@echo "$(BLUE)Starting in development mode...$(NC)"
	@GPU_FLAG=""; \
	if [ "$(DEVICE)" != "cpu" ] && command -v nvidia-smi >/dev/null 2>&1; then \
		GPU_FLAG="--gpus all"; \
	fi; \
	docker run -it --rm \
		--name medrax-dev \
		$$GPU_FLAG \
		-p 11180:8585 \
		-v $$(pwd):/medrax \
		-v $$(pwd)/temp:/medrax/temp \
		-v $$(pwd)/logs:/medrax/logs \
		-e OPENAI_API_KEY="$$OPENAI_API_KEY" \
		-e OPENAI_BASE_URL="$$OPENAI_BASE_URL" \
		bowang-lab--medrax_image:latest \
		bash

## validate: Validate environment configuration
validate:
	@echo "$(BLUE)Validating configuration...$(NC)"
	@if [ -z "$$OPENAI_API_KEY" ] && ! grep -q "OPENAI_API_KEY" .env 2>/dev/null; then \
		echo "$(YELLOW)⚠$(NC) OPENAI_API_KEY is not set"; \
		exit 1; \
	else \
		echo "$(GREEN)✓$(NC) OPENAI_API_KEY is set"; \
	fi
	@if [ -f .env ]; then \
		echo "$(GREEN)✓$(NC) .env file exists"; \
	else \
		echo "$(YELLOW)⚠$(NC) .env file not found"; \
	fi
	@if [ -d model-weights ]; then \
		echo "$(GREEN)✓$(NC) model-weights directory exists"; \
	else \
		echo "$(YELLOW)⚠$(NC) model-weights directory not found (will auto-download)"; \
	fi
	@echo "$(GREEN)Validation complete!$(NC)"

## test: Run quick test of the container
test: start
	@echo "$(BLUE)Running container health check...$(NC)"
	@sleep 5
	@docker exec medrax-container python -c "import gradio; print('Gradio version:', gradio.__version__)"
	@echo "$(GREEN)✓$(NC) Container is healthy"

## update: Pull latest code and rebuild
update:
	@echo "$(BLUE)Updating MedRAX...$(NC)"
	@git pull
	@$(MAKE) build
	@$(MAKE) restart
	@echo "$(GREEN)✓$(NC) Update complete"

## version: Show version information
version:
	@echo "$(BLUE)Version Information:$(NC)"
	@docker --version
	@docker-compose --version 2>/dev/null || echo "docker-compose: not installed"
	@if docker images | grep -q "bowang-lab--medrax_image"; then \
		echo "MedRAX Image: built"; \
	else \
		echo "MedRAX Image: not built (run 'make build')"; \
	fi

