# Logging With Loki

## Purpose
This appendix explains where logging fits beside metrics in the local observability lab.
The main lab uses Prometheus metrics first because metrics are easier to validate in a short session.

## Mental Model
Metrics answer numeric questions over time.
Logs answer event and detail questions for specific moments.
Loki stores logs and lets Grafana query them with LogQL.

## Install Loki
Loki is kept in `infrastructure/kubernetes/helmfile-loki.yaml` instead of the core monitoring Helmfile.
Install it only when the session needs the logging appendix.

```bash
make logging-up
```

Expected outcome: Loki runs in the `logging` namespace.

```bash
kubectl --context kind-fivepercent-observability -n logging get pods
```

## What Is Included
The lab includes a pinned Loki Helm release and lightweight local values.
The values use single-binary mode and filesystem storage so the setup stays small for `kind`.

## What Is Not Included Yet
The lab does not deploy a log collector by default.
To complete the logging path, add a collector such as Promtail, Alloy, or another local-only agent that tails container logs and sends them to Loki.

## Suggested Teaching Flow
1. Show app logs directly with `kubectl --context kind-fivepercent-observability logs`.
2. Explain why direct log inspection does not scale across many pods.
3. Install Loki with `make logging-up`.
4. Add a collector in a later phase if the session needs full log querying.
5. Compare a metrics query in Prometheus with a log query in Grafana.

## Example Direct Log Check
```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs deploy/sample-metrics-app
```

Expected outcome: the app writes Flask request logs and Python runtime logs to stdout.

## Rollback
```bash
make logging-down
```

Expected outcome: the optional Loki release is removed from the local cluster.
