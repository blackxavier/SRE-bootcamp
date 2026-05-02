.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make compose-up     - Start the EC2 deployment stack"
	@echo "  make compose-down   - Stop the EC2 deployment stack"
	@echo "  make compose-logs   - Tail stack logs"

.PHONY: compose-up
compose-up:
	docker compose up -d

.PHONY: compose-down
compose-down:
	docker compose down

.PHONY: compose-logs
compose-logs:
	docker compose logs -f
