# Validation

## Purpose
Use these checks before the session and after changes to the lab.

## Static Checks
Run these commands from `hape-academy/5percent/observability`.

```bash
make check-prereqs
kubectl kustomize infrastructure/kubernetes/apps/sample-metrics-app >/tmp/sample-metrics-app.yaml
kubectl kustomize infrastructure/kubernetes/dashboards >/tmp/sample-dashboard.yaml
kubectl kustomize infrastructure/kubernetes/alerts >/tmp/sample-alerts.yaml
helmfile -f infrastructure/kubernetes/helmfile.yaml build >/tmp/observability-helmfile.yaml
helmfile -f infrastructure/kubernetes/helmfile-loki.yaml build >/tmp/observability-loki-helmfile.yaml
helm show chart kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts --version 87.10.1 >/tmp/observability-kps-chart.yaml
helm show chart loki --repo https://grafana.github.io/helm-charts --version 6.55.0 >/tmp/observability-loki-chart.yaml
```

Expected outcome: each command exits successfully and writes rendered YAML to `/tmp`.

## Cluster Checks
Run these commands after `make kind-up` and `make monitoring-up`.

```bash
kubectl --context kind-fivepercent-observability get nodes
kubectl --context kind-fivepercent-observability -n monitoring get pods
kubectl --context kind-fivepercent-observability -n monitoring get svc kube-prometheus-stack-grafana
kubectl --context kind-fivepercent-observability -n monitoring get svc kube-prometheus-stack-prometheus
kubectl --context kind-fivepercent-observability -n monitoring get svc kube-prometheus-stack-alertmanager
```

Expected outcome: the cluster has one control-plane node, two worker nodes, and monitoring pods eventually become `Running`.

## App Checks
Run these commands after `make app-up`.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get deploy,svc,servicemonitor
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deploy/sample-metrics-app
```

Expected outcome: the app has two ready replicas, one service, and one `ServiceMonitor`.

## Metrics Checks
Port-forward the app and call the metrics endpoint.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward svc/sample-metrics-app 8080:80
curl http://localhost:8080/work
curl http://localhost:8080/metrics
```

Expected outcome: the metrics output includes `fivepercent_http_requests_total`, `fivepercent_http_request_duration_seconds`, and `fivepercent_business_events_total`.

## Prometheus Checks
Port-forward Prometheus.

```bash
make prometheus-port-forward
```

Open `http://localhost:9090` and run these queries.

```promql
up{namespace="fivepercent-observability"}
sum(rate(fivepercent_http_requests_total[5m]))
histogram_quantile(0.95, sum by (le) (rate(fivepercent_http_request_duration_seconds_bucket[5m])))
```

Expected outcome: Prometheus returns data for the sample app after traffic has been generated.

## Grafana Checks
Run these commands after `make dashboard-up`.

```bash
kubectl --context kind-fivepercent-observability -n monitoring get configmap sample-metrics-app-dashboard
make grafana-port-forward
```

Expected outcome: Grafana loads a dashboard named `5percent Sample Metrics App`.

## Rollback Checks
Remove lab components in reverse order when testing cleanup.

```bash
make alerts-down
make dashboard-down
make app-down
make monitoring-down
make logging-down
make kind-down
```

Expected outcome: each target succeeds or reports that the target resource is already absent.
