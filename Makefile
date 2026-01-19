# ============================================================================ #
# VARIABLES                                                                    #
# ============================================================================ #

# Name of the project
NAME = inception

# Path to docker compose file
COMPOSE_FILE = srcs/docker-compose.yml

# Path where volumes will be stored on the host
# The subject requires: /home/login/data
DATA_PATH = /home/$(USER)/data

# Volume directories
WORDPRESS_VOLUME = $(DATA_PATH)/wordpress
MARIADB_VOLUME = $(DATA_PATH)/mariadb

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m

# ============================================================================ #
# MAIN TARGETS                                                                 #
# ============================================================================ #

# Default target: create volumes and start everything
# This is what gets executed when you just type "make"
all: create_volumes up

# Create the volume directories on the host machine
# These directories persist data even when containers are deleted
create_volumes:
	@echo "$(BLUE)Creating volume directories...$(NC)"
	@mkdir -p $(WORDPRESS_VOLUME)
	@mkdir -p $(MARIADB_VOLUME)
	@echo "$(GREEN)✓ Volumes created at $(DATA_PATH)$(NC)"

# Build Docker images and start all containers
# -d: detached mode (runs in background)
# --build: rebuild images even if they exist
up:
	@echo "$(BLUE)Building and starting $(NAME)...$(NC)"
	@docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(GREEN)✓ $(NAME) is running!$(NC)"
	@echo "$(YELLOW)→ Access the website at: https://$(USER).42.fr$(NC)"
	@echo "$(YELLOW)→ Use "make help" to see available commands.(NC)"


# Stop and remove all containers
# Keeps images and volumes (data is preserved)
down:
	@echo "$(BLUE)Stopping $(NAME)...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

# Remove everything: containers, images, volumes
# WARNING: This deletes Docker volumes but not host directories
clean: down
	@echo "$(RED)Cleaning Docker resources...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(GREEN)✓ Docker cleaned$(NC)"

# Full clean: also remove data directories from host
# WARNING: This permanently deletes ALL data (database, wordpress files)
fclean: clean
	@echo "$(RED)Removing data directories...$(NC)"
	@sudo rm -rf $(DATA_PATH)
	@echo "$(GREEN)✓ All data removed$(NC)"

# Rebuild everything from scratch
re: fclean all

# ============================================================================ #
# UTILITY TARGETS                                                              #
# ============================================================================ #

# Show container status
status:
	@echo "$(BLUE)Container status:$(NC)"
	@docker compose -f $(COMPOSE_FILE) ps

# Show logs from all containers
# Press Ctrl+C to stop following logs
logs:
	@echo "$(BLUE)Showing logs (Ctrl+C to stop)...$(NC)"
	@docker compose -f $(COMPOSE_FILE) logs -f

# Display help information about available commands
help:
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)  $(NAME) - Available Commands$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "$(GREEN)Main commands:$(NC)"
	@echo "  make          - Build and start everything"
	@echo "  make up       - Build and start containers"
	@echo "  make down     - Stop and remove containers"
	@echo ""
	@echo "$(GREEN)Cleaning commands:$(NC)"
	@echo "  make clean    - Remove containers, images, and volumes"
	@echo "  make fclean   - Full clean including data directories"
	@echo "  make re       - Rebuild everything from scratch"
	@echo ""
	@echo "$(GREEN)Information commands:$(NC)"
	@echo "  make status   - Show container status"
	@echo "  make logs     - Show all logs (follow mode)"
	@echo "  make help     - Display this help message"
	@echo ""
	@echo "$(YELLOW)Website URL: https://$(USER).42.fr$(NC)"
	@echo ""

# ============================================================================ #
# PHONY                                                                        #
# ============================================================================ #

# Declare targets that don't create files
.PHONY: all create_volumes up down clean fclean re ps logs help
