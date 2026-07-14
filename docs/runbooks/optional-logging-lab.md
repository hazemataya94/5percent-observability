# Optional Logging Lab

## Purpose
This optional runbook compares direct Kubernetes log inspection with the boundary of the local Loki installation.
Read [Fundamentals 10: Logging](../fundamentals/10-logging-fundamentals.md) for the theory and [Logging With Loki](../appendices/logging-with-loki.md) for the deeper component explanation.

## Prerequisites
- Complete the [Core Observability Lab](core-observability-lab.md) through application deployment.
- Work from `hape-academy/5percent/observability`.
- Keep the local `kind-fivepercent-observability` cluster and sample app running.
- Keep at least 512 MiB of local cluster memory available for the optional Loki container limit.

Verify that the app pods are ready.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get pods -l app.kubernetes.io/name=sample-metrics-app
```

Expected outcome: two sample app pods report `Running` and ready.

## Checkpoint: Inspect Logs And Loki Boundaries
Inspect recent application logs directly through the Kubernetes API.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs -l app.kubernetes.io/name=sample-metrics-app --all-containers=true --tail=50 --prefix=true
```

Expected outcome: the output contains startup or HTTP request records from the sample app pods.

Explanation: `kubectl logs` reads container stdout and stderr for selected pods and is sufficient for a small local inspection.
It does not provide a central historical query path across changing pods.

If you need fresh request records, expose the app in terminal 1.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability port-forward service/sample-metrics-app 8080:80
```

In terminal 2, call the app, then repeat the `kubectl logs` command.

```bash
curl http://localhost:8080/
curl http://localhost:8080/work
```

Stop the app port-forward with `Ctrl-C` when the direct log check is complete.

The Loki installation is optional.
Skip the remaining installation steps if you only need the direct Kubernetes log exercise.

Install Loki through the local Helmfile target.

```bash
make logging-up
```

Inspect the installed resources and wait for the single-binary Loki StatefulSet.

```bash
kubectl --context kind-fivepercent-observability -n logging get statefulsets,pods,services
kubectl --context kind-fivepercent-observability -n logging rollout status statefulset/loki --timeout=5m
```

Expected outcome: the `loki` StatefulSet reaches its ready state and the Loki resources run in the `logging` namespace.

Explanation: this lab installs Loki in single-binary mode with local filesystem storage and no persistent volume.

The lab does not deploy a log collector.
Without a collector, the sample application's container logs are not ingested into Loki.
Do not run or present LogQL queries for the sample app because no sample app log stream exists in Loki.
Installing the storage component alone does not create a complete logging pipeline.

The boundary is:

```text
sample app stdout -> kubectl logs
sample app stdout -X-> Loki because no collector is installed
```

Expected outcome: you can explain that direct app logs are available through Kubernetes while Loki has no ingestion path for those app logs.

Validation: identify the missing collector role that would read container logs, add labels, and send entries to Loki, without adding that component to this lab.

## Validation
Confirm the direct log path still works.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs -l app.kubernetes.io/name=sample-metrics-app --all-containers=true --tail=10 --prefix=true
```

If Loki was installed, confirm its workload status.

```bash
kubectl --context kind-fivepercent-observability -n logging get statefulset loki
kubectl --context kind-fivepercent-observability -n logging get pods
```

Expected outcome: direct app logs are readable and, when installed, Loki is ready as a storage component.
This validation does not claim that application logs are stored in Loki.

## Troubleshooting
If direct logs are empty, generate a request and select the pods again.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability get pods -l app.kubernetes.io/name=sample-metrics-app
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs -l app.kubernetes.io/name=sample-metrics-app --all-containers=true --tail=50 --prefix=true
```

If Loki does not become ready, inspect the StatefulSet, pod status, and namespace events.

```bash
kubectl --context kind-fivepercent-observability -n logging describe statefulset loki
kubectl --context kind-fivepercent-observability -n logging get pods
kubectl --context kind-fivepercent-observability -n logging get events --sort-by=.lastTimestamp
```

If a Grafana log view has no sample app streams, treat that as expected because the lab has no collector.

## Cleanup
Remove Loki if it was installed.

```bash
make logging-down
```

Expected outcome: the optional Loki Helm release and workloads are removed from the local cluster.
The `logging` namespace may remain empty after the Helm release is removed.

Verify that the Loki StatefulSet is absent.

```bash
kubectl --context kind-fivepercent-observability -n logging get statefulset loki
```

Expected outcome: Kubernetes reports that the StatefulSet is not found.

This cleanup does not remove the core metrics lab.
