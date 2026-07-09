# Observability Lab Runbook

## Purpose
This runbook provides the local operating steps for the 5percent observability lab.

## Start The Lab
Run these commands from `hape-academy/5percent/observability`.

```bash
make check-prereqs
make kind-up
make monitoring-up
make app-up
make dashboard-up
```

Expected outcome: the sample app runs in the `fivepercent-observability` namespace and monitoring runs in the `monitoring` namespace.

## Open Grafana
```bash
make grafana-port-forward
```

Open `http://localhost:3000`.
Use `admin` / `admin` for the local lab.

## Open Prometheus
```bash
make prometheus-port-forward
```

Open `http://localhost:9090`.
Query `fivepercent_http_requests_total` after generating traffic.

## Generate Traffic
```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward svc/sample-metrics-app 8080:80
curl http://localhost:8080/
curl http://localhost:8080/work
curl http://localhost:8080/work
curl http://localhost:8080/metrics
```

Expected outcome: Prometheus and Grafana show changing request and business-event metrics.

## Apply Alerts
```bash
make alerts-up
make alertmanager-port-forward
```

Open `http://localhost:9093`.
Expected outcome: Alertmanager is reachable and can receive alerts from Prometheus.

## Optional Logging
```bash
make logging-up
```

Expected outcome: Loki installs in the `logging` namespace.
This target is optional and not required for the main metrics session.

## Troubleshooting
If Prometheus does not scrape the app, check the `ServiceMonitor` label.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app --show-labels
```

Expected outcome: the labels include `release=kube-prometheus-stack`.

If Grafana does not show the dashboard, check the dashboard ConfigMap label.

```bash
kubectl --context kind-fivepercent-observability -n monitoring get configmap sample-metrics-app-dashboard --show-labels
```

Expected outcome: the labels include `grafana_dashboard=1`.

If the app image is not found, rebuild and reload the image.

```bash
make app-build
make app-load
make app-up
```

## Rollback
Use the narrowest rollback first.

```bash
make alerts-down
make dashboard-down
make app-down
make monitoring-down
make logging-down
make kind-down
```

Use `make clean` when the whole local cluster can be deleted.
