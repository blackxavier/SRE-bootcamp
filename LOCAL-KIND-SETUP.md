# Local Kubernetes Test Guide

This guide lets you test the Helm-based deployment locally on Ubuntu 26.04
without keeping the AWS Kubernetes server running.

It covers:

- Docker Engine
- Minikube with a 3-node cluster
- kubectl
- Helm
- Deploying this project into Minikube
- Port forwarding to reach the app locally

---

## 1. What You Will End Up With

After following this guide, you will have:

- Docker running locally on Ubuntu 26.04
- a Minikube cluster with 3 nodes
- kubectl connected to that cluster
- Helm installed locally
- this project deployed into the cluster with the existing chart

The application will be reachable locally through port forwarding, for example:

- http://127.0.0.1:8080/api/v1/health/
- http://127.0.0.1:8080/api/v1/students/

---

## 2. Prerequisites

This guide assumes:

- Ubuntu 26.04
- a user with `sudo` access
- internet access for package downloads
- virtualization already available on the machine

---

## 3. Install Docker Engine

Update the system:

```bash
sudo apt update
sudo apt upgrade -y
```

Install Docker from the Ubuntu repositories:

```bash
sudo apt install -y docker.io
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Allow your user to run Docker without `sudo`:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

Verify:

```bash
docker version
docker info
```

---

## 4. Install kubectl

```bash
sudo snap install kubectl --classic
```

Verify:

```bash
kubectl version --client
```

---

## 5. Install Helm

Use the official install script:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

## 6. Install Minikube

Download and install the latest Linux binary:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
```

Verify:

```bash
minikube version
```

---

## 7. Create a 3-Node Minikube Cluster

Start Minikube using the Docker driver and 3 nodes:

```bash
minikube start \
  -p sre-bootcamp \
  --driver=docker \
  --nodes=3 \
  --cpus=2 \
  --memory=4096 \
  --kubernetes-version=stable
```

Why this works well locally:

- Docker is the simplest local Minikube driver on Ubuntu
- `--nodes=3` gives you a small multi-node cluster close to your EC2 layout
- Minikube includes a default storage class, which helps your Postgres PVC bind

Verify the cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

You should see 3 nodes.

---

## 8. Point kubectl at the Minikube Cluster

Minikube usually updates your kubeconfig automatically.

Check the current context:

```bash
kubectl config current-context
```

If needed, switch to the Minikube profile context:

```bash
kubectl config use-context sre-bootcamp
```

If that context name does not exist, inspect available contexts:

```bash
kubectl config get-contexts
```

---

## 9. Create the Namespace and Secret

The chart expects a pre-existing secret named `db-credentials` in the
`sre-bootcamp` namespace.

Create the namespace:

```bash
kubectl create namespace sre-bootcamp --dry-run=client -o yaml | kubectl apply -f -
```

Create the secret:

```bash
kubectl -n sre-bootcamp create secret generic db-credentials \
  --from-literal=DB_NAME=sre_bootcamp \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASSWORD=postgres \
  --dry-run=client -o yaml | kubectl apply -f -
```

This is idempotent and safe to rerun.

---

## 10. Deploy the Chart Locally

From the repository root:

```bash
helm lint ./helm/sre-bootcamp
helm template sre-bootcamp ./helm/sre-bootcamp
```

Then install or upgrade:

```bash
helm upgrade --install sre-bootcamp ./helm/sre-bootcamp \
  --namespace sre-bootcamp \
  --set web.image.tag=latest
```

Why `upgrade --install`:

- first run: it behaves like `helm install`
- later runs: it behaves like `helm upgrade`

Check release status:

```bash
helm list -n sre-bootcamp
kubectl -n sre-bootcamp get all
```

---

## 11. About the App Image in Local Minikube

Your chart defaults to:

```yaml
web:
  image:
    repository: ghcr.io/blackxavier/sre-bootcamp-web
    tag: latest
```

You have two ways to run locally.

### Option A: Pull from GHCR

Use this if the image already exists publicly in GHCR:

```bash
helm upgrade --install sre-bootcamp ./helm/sre-bootcamp \
  --namespace sre-bootcamp \
  --set web.image.tag=latest
```

### Option B: Build locally and load into Minikube

Use this if you want to test local code changes before pushing.

Build the image:

```bash
docker build -t sre-bootcamp-web:local .
```

Load it into Minikube:

```bash
minikube image load sre-bootcamp-web:local -p sre-bootcamp
```

Deploy with local image values:

```bash
helm upgrade --install sre-bootcamp ./helm/sre-bootcamp \
  --namespace sre-bootcamp \
  --set web.image.repository=sre-bootcamp-web \
  --set web.image.tag=local \
  --set web.image.pullPolicy=IfNotPresent
```

This is usually the best local workflow.

---

## 12. Port Forwarding and Local Access

The simplest way to reach the app locally is to port-forward the nginx service.

Run this in a separate terminal:

```bash
kubectl -n sre-bootcamp port-forward service/nginx 8080:80
```

Then test the app:

```bash
curl http://127.0.0.1:8080/api/v1/health/
curl http://127.0.0.1:8080/api/v1/students/
```

Alternative command using Minikube's service helper:

```bash
minikube service nginx -n sre-bootcamp -p sre-bootcamp --url
```

Use `kubectl port-forward` when you want a stable, explicit local port.

---

## 13. Verify the Deployment

Watch pods:

```bash
kubectl -n sre-bootcamp get pods -w
```

Check services:

```bash
kubectl -n sre-bootcamp get svc
```

Check the release:

```bash
helm status sre-bootcamp -n sre-bootcamp
```

Check PVCs:

```bash
kubectl -n sre-bootcamp get pvc
```

---

## 14. Useful Troubleshooting

### Pods not starting

```bash
kubectl -n sre-bootcamp get pods
kubectl -n sre-bootcamp describe pod <pod-name>
kubectl -n sre-bootcamp logs deployment/sre-bootcamp-web --tail=200
kubectl -n sre-bootcamp logs deployment/nginx --tail=200
kubectl -n sre-bootcamp logs deployment/db --tail=200
```

### PVC not binding

The chart now defaults Postgres storage to `pvc`. Minikube usually provides a
default storage class, but verify it:

```bash
kubectl get storageclass
kubectl -n sre-bootcamp get pvc
kubectl -n sre-bootcamp describe pvc postgres-pvc
```

If you want to bypass PVC for a quick test:

```bash
helm upgrade --install sre-bootcamp ./helm/sre-bootcamp \
  --namespace sre-bootcamp \
  --set postgres.storage.type=emptyDir
```

### Port-forward not working

Check that the nginx service exists:

```bash
kubectl -n sre-bootcamp get svc nginx
kubectl -n sre-bootcamp get endpoints nginx
```

If port `8080` is already busy, use a different local port:

```bash
kubectl -n sre-bootcamp port-forward service/nginx 9090:80
```

Then browse `http://127.0.0.1:9090/`.

### Reset everything

Delete the Helm release:

```bash
helm uninstall sre-bootcamp -n sre-bootcamp
```

Delete the Minikube cluster:

```bash
minikube delete -p sre-bootcamp
```

---

## 15. Recommended Local Workflow

For day-to-day local testing:

1. Start Docker.
2. Start the Minikube cluster once.
3. Build the app image locally.
4. Load the image into Minikube.
5. Run `helm upgrade --install`.
6. Run `kubectl port-forward service/nginx 8080:80 -n sre-bootcamp`.
7. Test at `http://127.0.0.1:8080/api/v1/health/`.

This gives you a cheap local replacement for the AWS test cluster while keeping
the same Helm chart and a close Kubernetes runtime model.