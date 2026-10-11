# SRE Bootcamp - Kubernetes Mastery Roadmap (Minikube on EC2)

This roadmap outlines the milestones to progress from the current working baseline to a production-grade Kubernetes architecture on **Minikube**.

---

## 📌 Cluster Context
- **Runtime:** Minikube (3-node cluster, `--driver=docker`) on Ubuntu EC2.
- **CLI Standard:** `minikube kubectl -- <cmd>` or `kubectl` with active context `sre-bootcamp`.
- **Namespace:** `sre-bootcamp`.
- **Access Pattern:** NodePort (`30080`) bridged to EC2 public IP via `port-forward` / `socat`.

---

## Phase 1: State & Persistence (Postgres Persistence)
Currently, `k8s/postgres.yaml` uses `emptyDir: {}`. Restarting the Postgres pod permanently destroys all database data.

- [ ] **1.1 Verify Minikube StorageClass**
  - Ensure default storageclass addon is active:
    ```bash
    minikube addons enable default-storageclass -p sre-bootcamp
    minikube kubectl -- get storageclass
    ```
- [ ] **1.2 Create PersistentVolumeClaim (PVC)**
  - Define `postgres-pvc` requesting 1Gi with `storageClassName: standard` and `accessModes: [ReadWriteOnce]`.
- [ ] **1.3 Attach PVC to Postgres**
  - Replace `emptyDir: {}` in `k8s/postgres.yaml` with `persistentVolumeClaim: { claimName: postgres-pvc }`.
- [ ] **1.4 Convert Postgres from Deployment to StatefulSet**
  - Change `kind: Deployment` to `kind: StatefulSet`.
  - Add Headless Service (`clusterIP: None`) for stable network identity (`db-0`).
  - Use `volumeClaimTemplates` to provision storage per replica automatically.
- [ ] **1.5 Persistence Chaos Test**
  - Populate data via `POST /api/v1/students/`.
  - Force delete the pod: `minikube kubectl -- -n sre-bootcamp delete pod db-0`.
  - Verify that student data persists once the replacement pod boots up.

---

## Phase 2: Ingress & Modern Networking (Retiring NodePort)
Replace manual `port-forward` and high NodePorts with standard HTTP/HTTPS reverse proxying.

- [ ] **2.1 Enable Minikube Ingress Addon**
  ```bash
  minikube addons enable ingress -p sre-bootcamp
  minikube kubectl -- -n ingress-nginx get pods -w
  ```
- [ ] **2.2 Create Ingress Manifest (`k8s/ingress.yaml`)**
  - Define rules routing `/api/v1/` to `nginx` service or directly to `sre-bootcamp-web`.
  - Support domain-based routing (e.g. `api.srebootcamp.local`).
- [ ] **2.3 Host Port Binding**
  - Connect host port 80 to the Ingress controller so traffic flows without manual port forwarding.
- [ ] **2.4 TLS Termination with cert-manager (Optional / Advanced)**
  - Install cert-manager and configure self-signed or Let's Encrypt certificates.

---

## Phase 3: Autoscaling & Self-Healing
Ensure Django can handle spiky workloads and recover from node/process failure.

- [ ] **3.1 Enable Minikube Metrics Server**
  ```bash
  minikube addons enable metrics-server -p sre-bootcamp
  minikube kubectl -- top nodes
  minikube kubectl -- -n sre-bootcamp top pods
  ```
- [ ] **3.2 Fine-Tune Resource Requests & Limits**
  - Ensure `sre-bootcamp-web` defines realistic `cpu` and `memory` requests and limits.
- [ ] **3.3 Configure Horizontal Pod Autoscaler (HPA)**
  - Create an HPA manifest for `sre-bootcamp-web`:
    - Min replicas: 2
    - Max replicas: 6
    - Target CPU utilization: 70%
- [ ] **3.4 Stress Testing**
  - Use `hey`, `ab` (Apache Bench), or `k6` to drive traffic to `/api/v1/students/` and observe pods autoscaling.
- [ ] **3.5 PodDisruptionBudget (PDB)**
  - Define a PDB requiring `minAvailable: 1` during node maintenance.

---

## Phase 4: Release Engineering & Helm Migration
Transition raw `k8s/` manifests into the parameterized chart under `helm/sre-bootcamp/`.

- [ ] **4.1 Validate & Lint Helm Chart**
  ```bash
  helm lint helm/sre-bootcamp
  ```
- [ ] **4.2 Multi-Environment Configuration**
  - Maintain `values-dev.yaml` and `values-prod.yaml`.
- [ ] **4.3 Test Helm Deployments on Minikube**
  ```bash
  helm upgrade --install sre-bootcamp helm/sre-bootcamp -n sre-bootcamp --create-namespace
  ```
- [ ] **4.4 Rollback Simulation**
  - Deploy a deliberately broken container tag.
  - Execute a clean `helm rollback sre-bootcamp 1 -n sre-bootcamp`.

---

## Phase 5: Observability & Production Operations
Monitor logs, application health, and cluster events.

- [ ] **5.1 Prometheus & Grafana Monitoring**
  - Deploy lightweight monitoring or `kube-prometheus-stack` to collect node & container metrics.
- [ ] **5.2 Django Application Metrics**
  - Add request rate, latency, and status code metrics via `django-prometheus`.
- [ ] **5.3 Automated Alerts**
  - Configure alerts for high error rates (5xx), Pod CrashLooping, and PVC disk capacity (>80%).
