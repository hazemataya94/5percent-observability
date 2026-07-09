# Alerting With Alertmanager

## Purpose
This appendix explains how alerting works in the local lab.
The main session focuses on metrics, while this appendix shows how Prometheus turns rules into alerts and sends them to Alertmanager.

## Components
- `PrometheusRule` stores alert expressions as Kubernetes custom resources.
- Prometheus loads matching `PrometheusRule` objects through the Prometheus Operator.
- Alertmanager receives firing alerts and owns grouping, silencing, inhibition, and notification routing.
- Grafana can query Alertmanager as a datasource through the kube-prometheus-stack configuration.

## Apply Sample Alerts
```bash
make alerts-up
```

Expected outcome: the `sample-metrics-app-alerts` rule exists in the `fivepercent-observability` namespace.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts
```

## Open Alertmanager
```bash
make alertmanager-port-forward
```

Open `http://localhost:9093`.

## Teaching Flow
1. Show the `FivePercentSampleAppDown` rule in `infrastructure/kubernetes/alerts/sample-app-alerts.yaml`.
2. Explain the `expr`, `for`, `labels`, and `annotations` fields.
3. Scale the app to zero replicas to trigger the down alert.
4. Scale the app back to two replicas to resolve the alert.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deploy/sample-metrics-app --replicas=0
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deploy/sample-metrics-app --replicas=2
```

## Validation
Query Prometheus for the alert state.

```promql
ALERTS{alertname="FivePercentSampleAppDown"}
```

Expected outcome: Prometheus shows the alert as pending or firing when the app is unavailable.

## Rollback
```bash
make alerts-down
```

Expected outcome: the sample `PrometheusRule` is deleted.
