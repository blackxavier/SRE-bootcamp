.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make compose-up     - Start the EC2 deployment stack"
	@echo "  make compose-down   - Stop the EC2 deployment stack"
	@echo "  make compose-logs   - Tail stack logs"
	@echo "  make minikube-up    - Start 3-node Minikube cluster (sre-bootcamp)"
	@echo "  make minikube-down  - Delete Minikube cluster"
	@echo "  make minikube-status- Display Minikube nodes & storage class"
	@echo "  make minikube-load  - Build & load local image into Minikube"
	@echo "  make minikube-addons- Enable ingress and default-storageclass"

.PHONY: compose-up
compose-up:
	docker compose up -d

.PHONY: compose-down
compose-down:
	docker compose down

.PHONY: compose-logs
compose-logs:
	docker compose logs -f

.PHONY: minikube-up
minikube-up:
	minikube start \
		-p sre-bootcamp \
		--driver=docker \
		--nodes=3 \
		--cpus=2 \
		--memory=4096 \
		--kubernetes-version=stable

.PHONY: minikube-down
minikube-down:
	minikube delete -p sre-bootcamp

.PHONY: minikube-status
minikube-status:
	minikube status -p sre-bootcamp
	kubectl get nodes -o wide

.PHONY: minikube-addons
minikube-addons:
	minikube addons enable ingress -p sre-bootcamp
	minikube addons enable default-storageclass -p sre-bootcamp

.PHONY: minikube-load
minikube-load:
	docker build -t sre-bootcamp-web:local .
	minikube image load sre-bootcamp-web:local -p sre-bootcamp
