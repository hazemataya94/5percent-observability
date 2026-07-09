# Observability Lab Architecture

## Purpose
This document explains the local architecture for the 5percent observability lab.
The lab keeps platform setup, application workload, dashboards, and optional appendices separated so each teaching phase can be run independently.

## Component Topology
```mermaid
flowchart TD
  makefile["Makefile<br>learner entrypoint"] --> kind["kind cluster<br>fivepercent-observability"]
  makefile --> helmfile["Helmfile<br>platform charts"]
  makefile --> kustomize["Kustomize<br>workload resources"]

  helmfile --> kps["kube-prometheus-stack<br>monitoring namespace"]
  kps --> prometheus["Prometheus<br>metrics storage and query"]
  kps --> grafana["Grafana<br>dashboards"]
  kps --> alertmanager["Alertmanager<br>alert routing"]

  kustomize --> app["sample metrics app<br>fivepercent-observability namespace"]
  app --> metrics["/metrics<br>Prometheus format"]
  kustomize --> serviceMonitor["ServiceMonitor<br>scrape contract"]
  serviceMonitor --> prometheus
  prometheus --> grafana

  kustomize --> dashboard["Grafana dashboard ConfigMap<br>grafana_dashboard=1"]
  dashboard --> grafana

  kustomize --> rule["PrometheusRule<br>sample alerts"]
  rule --> prometheus
  prometheus --> alertmanager

  helmfile --> loki["optional Loki<br>logging namespace"]
```

## Runtime Flow
```mermaid
sequenceDiagram
  participant Learner
  participant Make as Makefile
  participant Kind as kind
  participant Helmfile
  participant Kubernetes
  participant Prometheus
  participant Grafana

  Learner->>Make: make kind-up
  Make->>Kind: create local cluster
  Learner->>Make: make monitoring-up
  Make->>Helmfile: sync kube-prometheus-stack
  Helmfile->>Kubernetes: install Prometheus, Grafana, Alertmanager
  Learner->>Make: make app-up
  Make->>Kubernetes: build, load, and apply sample app manifests
  Kubernetes->>Prometheus: ServiceMonitor exposes scrape configuration
  Prometheus->>Kubernetes: scrape /metrics on sample app pods
  Learner->>Make: make dashboard-up
  Make->>Kubernetes: apply Grafana dashboard ConfigMap
  Grafana->>Prometheus: query fivepercent_* metrics
```

## Boundary Rules
- `Makefile` owns local commands and hides repeated flags from learners.
- `infrastructure/kubernetes/helmfile.yaml` owns Helm chart releases.
- `infrastructure/kubernetes/apps/` owns workload manifests.
- `infrastructure/kubernetes/dashboards/` owns Grafana dashboard provisioning.
- `infrastructure/kubernetes/alerts/` owns Prometheus alert rules.
- `app/` owns the sample HTTP service and its metrics.

## Chart Compatibility
The monitoring stack pins `kube-prometheus-stack` chart `87.10.1`, which was the latest public chart release found in the Prometheus Community chart metadata on 2026-07-08.
The optional logging appendix pins Grafana Loki chart `6.55.0` from `https://grafana.github.io/helm-charts`.
The public Loki migration documentation identifies this as the final Grafana-repo Loki chart family before the community-chart migration path.

## Resource Model
The lab uses memory limits and CPU requests only.
This keeps the manifests compatible with the workspace Kubernetes rule that forbids CPU limits.
