# Core Observability Lab

## Purpose
This runbook is the canonical executable path for the local metrics lab.
It connects a running application to Kubernetes resources, raw Prometheus metrics, PromQL queries, Grafana panels, conceptual reliability targets, and a final observability design exercise.

## Prerequisites
- Work from `hape-academy/5percent/observability`.
- Complete the installation and operating-system notes in the [runbook index](README.md).
- Ensure Docker is running.
- Ensure `docker`, `helm`, `helmfile`, `kind`, `kubectl`, and `make` are available.
- Reserve local ports `3000`, `8080`, and `9090`.
- Use only the local `kind-fivepercent-observability` Kubernetes context.

Validate the tools and Docker daemon before creating the lab.

```bash
make check-prereqs
docker info >/dev/null
```

Expected outcome: the prerequisite check reports that all required tools are available and `docker info` exits successfully.

## Setup
Create the local cluster, install the monitoring stack, deploy the application, and load the dashboard.

```bash
make kind-up
kubectl --context kind-fivepercent-observability cluster-info
make monitoring-up
make app-up
make dashboard-up
```

Expected outcome: the local cluster responds, the monitoring components run in `monitoring`, and the sample application runs in `fivepercent-observability`.

The port-forward commands used later remain in the foreground.
Run each active port-forward in its own terminal and run `curl` commands or browser checks from other terminals.
Stop a port-forward with `Ctrl-C` when it is no longer needed.

## Expected Outcomes
- Explain the path from the application metrics endpoint to a Grafana panel.
- Inspect the Kubernetes resources that make Prometheus discovery work.
- Read raw application metrics and query stored samples with PromQL.
- Map available and missing metrics to the golden signals.
- Interpret every panel in the provided Grafana dashboard.
- Draft a conceptual SLI and SLO without claiming that the lab enforces them.
- Design a basic observability system for another small service.

## Explanation
The checkpoints move from the running system to its resources, emitted signals, stored queries, visual interpretation, and design choices.
Each checkpoint pairs an action with an expected outcome, an explanation of why it matters, and a validation check.

## Checkpoint 1: Understand The Running System
Inspect the core lab status.

```bash
make status
```

Expected outcome: the output shows the local kind nodes, monitoring pods, and the sample application's pods, Service, and `ServiceMonitor`.

Explanation:
- The sample app exposes Prometheus-format metrics at `/metrics`.
- The Kubernetes Service gives the app pods a stable target.
- The `ServiceMonitor` tells the Prometheus Operator how Prometheus should discover and scrape that Service.
- Prometheus stores time-series samples and evaluates PromQL.
- Grafana queries Prometheus and presents the results in dashboard panels.

Write the path in your own words before continuing.

```text
sample app /metrics -> Service -> ServiceMonitor -> Prometheus -> Grafana
```

Validation: your explanation should identify where metrics originate, how the scrape target is discovered, where samples are queried, and where they are visualized.

## Checkpoint 2: Inspect Kubernetes Resources
Inspect the resources that keep the app running and connect it to Prometheus.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get deployment sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get pods -l app.kubernetes.io/name=sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get service sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app
kubectl --context kind-fivepercent-observability -n monitoring get configmap sample-metrics-app-dashboard --show-labels
```

Expected outcome: the Deployment reports two ready replicas, two app pods are ready, the Service exposes port `80`, the `ServiceMonitor` exists, and the dashboard ConfigMap has `grafana_dashboard=1`.

Inspect the scrape contract in more detail.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app -o yaml
```

Explanation: the `ServiceMonitor` selects the app Service by label, selects the `fivepercent-observability` namespace, and requests `/metrics` from the named `http` port every 15 seconds.

Validation: confirm that the `ServiceMonitor` label includes `release: kube-prometheus-stack` and its Service selector matches `app.kubernetes.io/name: sample-metrics-app`.

## Checkpoint 3: Inspect Application Metrics
In terminal 1, expose the app Service on local port `8080`.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward svc/sample-metrics-app 8080:80
```

Keep terminal 1 running.
In terminal 2, generate traffic and inspect the raw metrics endpoint.

```bash
curl http://localhost:8080/
curl http://localhost:8080/work
curl http://localhost:8080/work
curl http://localhost:8080/work
curl http://localhost:8080/metrics
```

Expected outcome: `/work` returns synthetic event and latency data, while `/metrics` includes metric families beginning with `fivepercent_`.

Identify these application metrics in the response:
- `fivepercent_http_requests_total` is a counter labeled by method, endpoint, and status.
- `fivepercent_http_request_duration_seconds` is a histogram labeled by method and endpoint.
- `fivepercent_http_requests_in_progress` is a gauge.
- `fivepercent_business_events_total` is a counter labeled by event type.

Explanation: the endpoint exposes current metric samples as text, while Prometheus repeatedly scrapes and stores those samples as time series.

Validation: run additional `/work` requests and confirm that request and business-event counter values increase.

## Checkpoint 4: Verify Prometheus Scraping
Keep the app port-forward running if you want to generate more traffic.
In terminal 3, expose Prometheus on local port `9090`.

```bash
make prometheus-port-forward
```

Open `http://localhost:9090` and query the app scrape target.

```promql
up{namespace="fivepercent-observability", service="sample-metrics-app"}
```

Expected outcome: Prometheus returns one series per healthy app target with a value of `1`.

Open the Prometheus target page and locate the `sample-metrics-app` targets.
Both app replicas should report a healthy scrape state.

Explanation: an `up` value of `1` means the last scrape succeeded, while `0` means Prometheus discovered the target but could not scrape it.

Validation: confirm that Prometheus shows two healthy app targets and that their labels include the app namespace and Service.

## Checkpoint 5: Query Metrics With PromQL
Run these queries in Prometheus after generating traffic.

Request rate by endpoint and status:

```promql
sum by (endpoint, status) (rate(fivepercent_http_requests_total[5m]))
```

Overall request rate:

```promql
sum(rate(fivepercent_http_requests_total[5m]))
```

p95 latency by endpoint:

```promql
histogram_quantile(0.95, sum by (le, endpoint) (rate(fivepercent_http_request_duration_seconds_bucket[5m])))
```

Business events observed during the last five minutes:

```promql
sum by (event_type) (increase(fivepercent_business_events_total[5m]))
```

Current in-progress requests:

```promql
sum(fivepercent_http_requests_in_progress)
```

Expected outcome: request-rate, latency, and business-event queries return data after traffic has been generated, while the in-progress gauge usually returns a small value or zero.

Explanation:
- `rate()` converts a counter into an average per-second rate over a range.
- `increase()` estimates how much a counter increased during a range.
- `histogram_quantile()` estimates a latency percentile from histogram buckets.
- `sum by (...)` preserves selected labels while combining the other series.

Validation: generate more `/work` traffic in terminal 2 and confirm that the request-rate and business-event query results change.

## Checkpoint 6: Map The Golden Signals
Map the available metrics to the four golden signals.

- Traffic is represented by the rate of `fivepercent_http_requests_total`.
- Errors can be represented by requests whose `status` label matches `5xx`, although the normal lab path may produce no errors.
- Latency is represented by percentiles derived from `fivepercent_http_request_duration_seconds_bucket`.
- Saturation is only approximated by `fivepercent_http_requests_in_progress`, so this signal is weak in the current lab.

Use this error-rate query as a reading exercise.

```promql
sum(rate(fivepercent_http_requests_total{status=~"5.."}[5m]))
/
clamp_min(sum(rate(fivepercent_http_requests_total[5m])), 0.001)
```

Expected outcome: the query is zero or returns no error series during normal requests because the provided endpoints normally return successful responses.

Explanation: a useful observability design states both which signals are covered and which signals are missing or weak.

Validation: record one current metric or proposed metric for each golden signal and mark whether the lab already provides it.

## Checkpoint 7: Read The Grafana Dashboard
In terminal 4, expose Grafana on local port `3000`.

```bash
make grafana-port-forward
```

Open `http://localhost:3000` and sign in with the local lab credentials `admin` and `admin`.
Open the dashboard named `5percent Sample Metrics App`.

Expected outcome: the dashboard shows request rate, p95 latency, synthetic business events, and scrape targets up.

Explanation: each panel turns a PromQL expression into a view that should answer a specific operational question.

Complete this exercise individually before comparing answers:
1. Is the app receiving traffic?
2. Is Prometheus scraping both app replicas successfully?
3. What does the p95 latency panel say about `/work` compared with the other endpoints?
4. Which panel would you check first after a report that the app feels slow?
5. Which panel would you check first if the app might not be monitored?
6. Which metric could support a basic availability alert?
7. Which golden signal is best covered by this dashboard?
8. Which golden signal is weakest or missing?
9. Which panel is useful for application behavior but not directly for service health?
10. What one panel would you add, and which question would it answer?

Validation: every answer should name a panel or query and explain the question that signal can or cannot answer.

## Checkpoint 8: Derive A Conceptual SLI And SLO
Choose one measured signal as a conceptual service-level indicator.

Example conceptual SLI:
- The proportion of observed requests that return a non-5xx status.

Example conceptual SLO:
- At least 99 percent of observed requests are non-5xx during a chosen measurement window.

Expected outcome: you can state one measured indicator and one target for that indicator without changing the lab configuration.

Explanation: the SLI defines what is measured, while the SLO defines the desired target over a stated window.
The lab does not configure or enforce this example objective.
The percentage and window are discussion inputs rather than validated commitments.

Validation: check that your SLI is derived from an available metric, your SLO has a numeric target and window, and neither statement claims the lab enforces it.

## Checkpoint 9: Design A Basic Observability System
Choose a small service you understand and create a one-page design using this template.

```text
Service purpose:
Users or callers:
Three to five metrics:
Metric type for each metric:
Golden signal supported by each metric:
Three dashboard panels and the question each answers:
One or two actionable alert conditions:
Logs needed for investigation:
One conceptual SLI:
One conceptual SLO:
Known gaps:
```

Expected outcome: the design connects service behavior to metrics, queries, dashboard questions, alert conditions, investigation logs, and a conceptual reliability target.

Explanation: observability starts with questions about a system and then selects signals and tools that answer those questions.

Validation: verify that every proposed metric has a clear owner question, metric type, label plan, dashboard use, or alert use.

## Validation
Run the resource checks after completing the checkpoints.

```bash
make status
kubectl --context kind-fivepercent-observability -n fivepercent-observability rollout status deployment/sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app --show-labels
kubectl --context kind-fivepercent-observability -n monitoring get configmap sample-metrics-app-dashboard --show-labels
```

Expected outcome: the app rollout succeeds, the `ServiceMonitor` has `release=kube-prometheus-stack`, and the dashboard ConfigMap has `grafana_dashboard=1`.

Complete the lab only after Prometheus returns healthy `up` series, at least one application PromQL query returns data, the Grafana dashboard loads, and the final design checkpoint is written.

## Troubleshooting
If `make kind-up` cannot connect to Docker, verify that the Docker daemon is running.

```bash
docker info
```

If monitoring components are not ready, inspect their status and recent events.

```bash
kubectl --context kind-fivepercent-observability -n monitoring get pods
kubectl --context kind-fivepercent-observability -n monitoring get events --sort-by=.lastTimestamp
```

If the app is not ready, inspect the Deployment and pods.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability describe deployment sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability get pods -l app.kubernetes.io/name=sample-metrics-app
```

If the app reports an image error, rebuild, reload, and apply the app through the existing targets.

```bash
make app-build
make app-load
make app-up
```

If Prometheus does not show the app targets, compare the Service and `ServiceMonitor` labels.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get service sample-metrics-app --show-labels
kubectl --context kind-fivepercent-observability -n fivepercent-observability get servicemonitor sample-metrics-app --show-labels
```

If Grafana does not load the dashboard, confirm that the sidecar label is present.

```bash
kubectl --context kind-fivepercent-observability -n monitoring get configmap sample-metrics-app-dashboard --show-labels
```

If a local port is already in use, stop the conflicting process or stop the earlier port-forward before retrying.

## Cleanup
Stop every active port-forward with `Ctrl-C`.
Remove the core components in reverse order.

```bash
make dashboard-down
make app-down
make monitoring-down
make kind-down
```

Expected outcome: the dashboard, app, monitoring release, and local kind cluster are removed.

Use `make clean` instead when the entire local lab cluster can be deleted in one step.
