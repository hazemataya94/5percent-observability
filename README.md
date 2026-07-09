# 5percent Observability Lab

## Purpose
This project is a local observability lab for a 5percent volunteering session.
It creates a `kind` cluster, installs `kube-prometheus-stack`, deploys a small metrics-producing app, and shows how Prometheus and Grafana observe that app.

## Prerequisites
- Docker Desktop or another local Docker runtime.
- `kind`.
- `kubectl`.
- `helmfile`.
- `helm`.
- `make`.

## Quick Start
Run all commands from this directory.

```bash
make check-prereqs
make kind-up
make monitoring-up
make app-up
make dashboard-up
make grafana-port-forward
```

Open `http://localhost:3000` and sign in with `admin` / `admin`.
This credential is only for the local `kind` lab.

Generate sample traffic in another terminal.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward svc/sample-metrics-app 8080:80
curl http://localhost:8080/
curl http://localhost:8080/work
curl http://localhost:8080/metrics
```

## Core Learning Flow
1. Start a local cluster with `kind`.
2. Install Prometheus, Grafana, and Alertmanager through `kube-prometheus-stack`.
3. Deploy a sample app that exposes Prometheus metrics.
4. Use a `ServiceMonitor` to tell Prometheus how to scrape the app.
5. Load a Grafana dashboard through the dashboard sidecar.
6. Add alerting rules and inspect Alertmanager routing.

## Optional Appendices
- `docs/appendices/logging-with-loki.md` explains how to add Loki for logs.
- `docs/appendices/alerting-with-alertmanager.md` explains how Prometheus rules reach Alertmanager.

## Cleanup
Remove the lab cluster when the session is done.

```bash
make clean
```

## Reference Pattern
This lab follows the structure used by `hape-framework/demos/eks-deployment-cost`: `kind` for local Kubernetes, Helmfile for platform components, Kustomize for workloads, and Make targets for reproducible steps.
