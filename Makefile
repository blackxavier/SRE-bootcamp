APP_NAME = sre-bootcamp-student-api
VERSION ?= 0.1.0
IMAGE = $(APP_NAME):$(VERSION)

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make build VERSION=X.Y.Z   - Build Docker image with semver tag"
	@echo "  make run VERSION=X.Y.Z     - Run container with env vars"
	@echo "  make push VERSION=X.Y.Z    - Push image to registry (if configured)"

.PHONY: build
build:
	docker build -t $(IMAGE) .

.PHONY: run
run:
	docker run --rm -p 8000:8000 -e DJANGO_SECRET_KEY="changeme" -e DEBUG="False" -e DB_NAME="sre_bootcamp" -e DB_USER="postgres" -e DB_PASSWORD="postgres" -e DB_HOST="localhost" -e DB_PORT="5432" $(IMAGE)

.PHONY: push
push:
	docker push $(IMAGE)

.PHONY: compose-up
compose-up:
	docker compose up --build

.PHONY: compose-down
compose-down:
	docker compose down

.PHONY: compose-logs
compose-logs:
	docker compose logs -f
