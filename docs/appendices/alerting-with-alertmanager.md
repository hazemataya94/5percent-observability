# Alerting With Alertmanager

## Purpose

This appendix provides a deeper explanation of how Prometheus evaluates the local sample rules and hands firing alerts to Alertmanager.

It complements the theory and executable runbook without duplicating the full procedure.

## Learning Path

1. Read [Fundamentals 09: Alerting](../fundamentals/09-alerting-fundamentals.md) for the alerting mental model.

2. Run [Optional Alerting Lab](../runbooks/optional-alerting-lab.md) for the canonical pending, firing, resolved, and rollback procedure.

3. Use this appendix to understand the resource fields and component boundaries in more detail.

## Components

- `PrometheusRule` stores alert expressions as Kubernetes custom resources.

- Prometheus loads matching `PrometheusRule` objects through the Prometheus Operator.

- Alertmanager receives firing alerts and owns grouping, silencing, inhibition, and notification routing.

- Grafana can query Alertmanager as a datasource through the kube-prometheus-stack configuration.

## Evaluation Flow

```text
PrometheusRule -> Prometheus rule evaluation -> pending -> firing -> Alertmanager
healthy target restored -> Prometheus resolves alert -> Alertmanager clears active alert
```

Prometheus, not Alertmanager, evaluates the PromQL expression.

The `for` field requires a condition to remain true before the alert changes from pending to firing.

Only firing alerts are sent to Alertmanager.

When the expression becomes false again, Prometheus sends the resolution update.

## Rule Anatomy

The local rules live in `infrastructure/kubernetes/alerts/sample-app-alerts.yaml`.

The `FivePercentSampleAppDown` rule contains:

- `expr` checks whether the healthy scrape-target sum is less than one or absent.

- `for: 1m` filters out conditions that recover before one continuous minute.

- `severity: warning` adds a label that can be used for grouping or routing.

- `summary` and `description` provide human-readable context.

The `FivePercentSampleAppHighErrorRate` rule divides the 5xx request rate by the total request rate.

`clamp_min` prevents an extremely small or zero denominator from making the expression invalid.

## Inspect The Applied Resource

Apply and trigger alerts through the [Optional Alerting Lab](../runbooks/optional-alerting-lab.md).

Use this command when you need to compare the live object with the source manifest.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get prometheusrule sample-metrics-app-alerts -o yaml
```

Expected outcome: the live rule includes the `release=kube-prometheus-stack` selection label and both sample alert definitions.

## Alert State Query

Query Prometheus for the current state during the optional exercise.

```promql
ALERTS{alertname="FivePercentSampleAppDown"}
```

The synthetic `ALERTS` series includes an `alertstate` label while an alert is pending or firing.

The series disappears after the rule resolves.

## Alertmanager Boundary

Alertmanager groups related firing alerts and provides local views for active alerts and silences.

The lab does not configure a notification receiver.

No email, chat message, or webhook is sent by this exercise.

## Design Questions

- Is the condition based on a symptom that requires action?

- Does the `for` duration avoid short-lived noise without hiding a meaningful outage?

- Do labels support useful grouping?

- Do annotations explain what happened and what to inspect?

- Can the condition be tested and reversed safely in the local lab?

## Validation And Rollback

Use the [Optional Alerting Lab validation and rollback](../runbooks/optional-alerting-lab.md#validation) as the executable source of truth.

The required final state is two ready application replicas with the optional `PrometheusRule` removed.
