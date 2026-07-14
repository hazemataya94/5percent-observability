# Logging With Loki

## Purpose
This appendix provides a deeper explanation of where direct container logs, collectors, Loki, and Grafana fit in a logging pipeline.
It complements the theory and executable runbook without claiming that the lab includes log ingestion.

## Learning Path
1. Read [Fundamentals 10: Logging](../fundamentals/10-logging-fundamentals.md) for the logging mental model.
2. Run [Optional Logging Lab](../runbooks/optional-logging-lab.md) for the canonical inspection, optional installation, validation, and cleanup procedure.
3. Use this appendix to understand the component boundaries and current omissions in more detail.

## Mental Model
Metrics answer numeric questions over time.
Logs answer event and detail questions for specific moments.
Loki can store labeled log streams and serve LogQL queries when another component sends logs to it.

## What Is Included
The optional Helmfile installs the pinned Loki chart in the `logging` namespace.
The local values use single-binary mode, one replica, filesystem storage, no persistence, and disabled caches.
The configuration keeps Loki separate from the core metrics stack.

```text
infrastructure/kubernetes/helmfile-loki.yaml
  -> grafana/loki chart
  -> logging namespace
  -> single Loki StatefulSet
```

The storage is ephemeral.
Removing the release or deleting the kind cluster removes its local data.

## What Is Not Included
The lab does not deploy a log collector by default.
No component tails the sample app container logs, adds stream labels, or sends entries to Loki.
The sample app logs are therefore not ingested into Loki.
LogQL queries for sample app logs do not work in this lab and should not be presented as a validation step.

## Pipeline Boundaries
The implemented path is:

```text
sample app -> container stdout and stderr -> Kubernetes pod logs -> kubectl logs
```

The conceptual centralized path would require an additional collector stage:

```text
sample app -> container logs -> collector -> Loki -> Grafana
```

The second path is a component model only and is not implemented by this lab.

## Direct Log Inspection
Use the [Optional Logging Lab](../runbooks/optional-logging-lab.md) for the complete exercise.
This command shows the currently implemented app-log path.

```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs -l app.kubernetes.io/name=sample-metrics-app --all-containers=true --tail=50 --prefix=true
```

Expected outcome: Kubernetes returns startup or HTTP request records from the selected app pods.

## Label Design
Loki indexes labels rather than the full contents of every log line.
A collector normally attaches bounded labels such as namespace, workload, container, or application name before sending a stream.
Unbounded values such as request identifiers should remain in the log content instead of becoming stream labels.

This distinction matters because every unique label set creates a separate stream.

## Design Questions
- Which events require logs rather than metrics?
- Which bounded labels are needed to find a workload's logs?
- Which values must remain in the log body?
- How long would local ephemeral storage be useful for the exercise?
- Which component owns collection, storage, and visualization?

## Validation And Cleanup
Use the [Optional Logging Lab validation and cleanup](../runbooks/optional-logging-lab.md#validation) as the executable source of truth.
The required final state is a functioning direct `kubectl logs` path with the optional Loki release removed after the exercise.
