# Optional Alerting Lab

## Purpose
This optional runbook demonstrates how a local `PrometheusRule` moves through pending, firing, and resolved states before Alertmanager displays the alert.
Read [Fundamentals 09: Alerting](../fundamentals/09-alerting-fundamentals.md) for the theory and [Alerting With Alertmanager](../appendices/alerting-with-alertmanager.md) for the deeper component explanation.

## Prerequisites
- Complete the [Core Observability Lab](core-observability-lab.md) through Prometheus scraping.
- Work from `hape-academy/5percent/observability`.
- Keep the local `kind-fivepercent-observability` cluster and monitoring stack running.
- Ensure the sample app Deployment is available with two replicas.
- Reserve local ports `9090` and `9093`.

Verify the starting state.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deployment/sample-metrics-app --replicas=2
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deployment/sample-metrics-app
```

Expected outcome: the Deployment reports two available replicas.

## Setup
Apply the sample alert rules.

```bash
make alerts-up
```

Expected outcome: the `sample-metrics-app-alerts` `PrometheusRule` exists in the application namespace.

This lab configures alert evaluation and local Alertmanager display only.
No notification receiver is configured, so no message is sent outside the local lab.

## Checkpoint: Inspect And Trigger An Alert
Inspect the applied rule and its source fields.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts -o yaml
```

Find the `FivePercentSampleAppDown` rule and identify its `expr`, `for`, `labels`, and `annotations`.

Expected outcome: the rule tests for fewer than one healthy app scrape target and requires the condition to remain true for one minute.

In terminal 1, expose Prometheus.

```bash
make prometheus-port-forward
```

In terminal 2, expose Alertmanager.

```bash
make alertmanager-port-forward
```

Keep both foreground processes running.
Open Prometheus at `http://localhost:9090` and Alertmanager at `http://localhost:9093`.

Before triggering the alert, run this Prometheus query.

```promql
ALERTS{alertname="FivePercentSampleAppDown"}
```

Expected outcome: the query returns no active `FivePercentSampleAppDown` series while the app has healthy scrape targets.

The trigger is optional.
If you trigger it, use terminal 3 for the following commands so its exit trap restores the app to two replicas if that terminal exits.

```bash
restore_sample_app() {
  kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deployment/sample-metrics-app --replicas=2
}
trap restore_sample_app EXIT INT TERM
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deployment/sample-metrics-app --replicas=0
```

Shortly after Prometheus observes that no healthy targets remain, run this query.

```promql
ALERTS{alertname="FivePercentSampleAppDown", alertstate="pending"}
```

Expected outcome: Prometheus returns a pending alert while the one-minute `for` duration has not completed.

After the condition remains true for at least one minute and another evaluation occurs, run this query.

```promql
ALERTS{alertname="FivePercentSampleAppDown", alertstate="firing"}
```

Expected outcome: Prometheus returns a firing alert and Alertmanager displays `FivePercentSampleAppDown` as active.

Alertmanager groups and displays the firing alert, but it does not send a notification because the lab has no notification receiver.

Restore the app from terminal 3 before leaving the checkpoint.

```bash
restore_sample_app
trap - EXIT INT TERM
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deployment/sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get deployment sample-metrics-app
```

Expected outcome: the Deployment returns to two ready replicas.

Run the alert query again after Prometheus observes healthy targets.

```promql
ALERTS{alertname="FivePercentSampleAppDown"}
```

Expected outcome: the active alert series disappears from Prometheus and the alert is no longer active in Alertmanager.
The disappearance of the active series after recovery is the resolved-state validation for this lab.

Explanation: Prometheus owns rule evaluation and state transitions, while Alertmanager receives firing alerts and handles grouping, silencing, inhibition, and routing.

## Validation
Confirm the rule remains applied, the app is restored, and its scrape targets are healthy.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts
kubectl --context kind-fivepercent-observability -n fivepercent-observability get deployment sample-metrics-app
```

Run this query in Prometheus.

```promql
sum(up{namespace="fivepercent-observability", service="sample-metrics-app"})
```

Expected outcome: the rule exists, the Deployment reports two ready replicas, the healthy-target sum is `2`, and no active `FivePercentSampleAppDown` alert remains.

## Troubleshooting
If the rule does not appear in Prometheus, verify its selection label.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts --show-labels
```

Expected outcome: the labels include `release=kube-prometheus-stack`.

If the alert remains pending, wait for the one-minute `for` duration and at least one additional Prometheus evaluation.

If the alert does not resolve, restore the app and verify the rollout and healthy scrape targets.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deployment/sample-metrics-app --replicas=2
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deployment/sample-metrics-app
```

If a port-forward stops, restart it in its own terminal.

## Rollback
Restore the application before removing the optional rule.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deployment/sample-metrics-app --replicas=2
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deployment/sample-metrics-app
make alerts-down
```

Stop the Prometheus and Alertmanager port-forwards with `Ctrl-C`.

Expected outcome: the app remains at two ready replicas and the sample `PrometheusRule` is absent.

Verify the rule removal.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts
```

Expected outcome: Kubernetes reports that the `PrometheusRule` is not found.
