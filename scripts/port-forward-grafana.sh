#!/usr/bin/env bash
set -euo pipefail

grafana_port="${GRAFANA_PORT:-3000}"
kind_context="kind-fivepercent-observability"

echo "Grafana will be available at http://localhost:${grafana_port}"
echo "Use the local lab credentials admin / admin."

kubectl --context "${kind_context}" -n monitoring port-forward svc/kube-prometheus-stack-grafana "${grafana_port}:80"
