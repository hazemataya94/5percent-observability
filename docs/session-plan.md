# Session Plan

## Purpose
This plan breaks the observability session into phases that can fit a short volunteering workshop.

## Audience Assumptions
- Learners can run local terminal commands.
- Learners have basic Kubernetes vocabulary such as Pod, Service, and Namespace.
- Learners do not need prior Prometheus or Grafana experience.

## Phase 1: Observability Mental Model
Explain the difference between metrics, logs, and traces.
Use this lab to focus on metrics first, then introduce logging and alerting as appendices.

Expected outcome: learners can explain why a `/metrics` endpoint is useful and why Prometheus pulls metrics.

## Phase 2: Local Platform Setup
Run the local platform commands.

```bash
make check-prereqs
make kind-up
make monitoring-up
```

Expected outcome: the `monitoring` namespace contains Prometheus, Grafana, and Alertmanager pods.

## Phase 3: App Metrics
Deploy the sample app.

```bash
make app-up
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward svc/sample-metrics-app 8080:80
```

Generate traffic.

```bash
curl http://localhost:8080/
curl http://localhost:8080/work
curl http://localhost:8080/metrics
```

Expected outcome: learners can see `fivepercent_*` metrics in raw Prometheus text format.

## Phase 4: Prometheus Discovery
Inspect the `ServiceMonitor`.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app -o yaml
```

Port-forward Prometheus.

```bash
make prometheus-port-forward
```

Expected outcome: learners can query `up{namespace="fivepercent-observability"}` and `fivepercent_http_requests_total`.

## Phase 5: Grafana Dashboard
Load and view the dashboard.

```bash
make dashboard-up
make grafana-port-forward
```

Expected outcome: learners can open Grafana at `http://localhost:3000` and inspect the `5percent Sample Metrics App` dashboard.

## Phase 6: Alerting Appendix
Apply sample alert rules.

```bash
make alerts-up
make alertmanager-port-forward
```

Expected outcome: learners can explain how `PrometheusRule` objects become Alertmanager alerts.

## Phase 7: Logging Appendix
Install optional Loki only if the session has enough time.

```bash
make logging-up
```

Expected outcome: learners understand where logs fit beside metrics, even if the main session does not fully instrument log shipping.

## Cleanup
Delete the local cluster.

```bash
make clean
```
