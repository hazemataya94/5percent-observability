# Sample Metrics App

## Purpose
This app is intentionally small so the session can focus on observability.
It exposes HTTP endpoints and Prometheus metrics that are scraped by the in-cluster Prometheus instance.

## Endpoints
- `/` returns a short service description and increments a synthetic page-view counter.
- `/healthz` returns a readiness and liveness response for Kubernetes probes.
- `/work` sleeps for a short randomized duration and increments synthetic business-event counters.
- `/metrics` exposes Prometheus metrics.

## Metrics
- `fivepercent_http_requests_total` counts requests by method, endpoint, and status.
- `fivepercent_http_request_duration_seconds` records request latency.
- `fivepercent_http_requests_in_progress` shows active requests.
- `fivepercent_business_events_total` counts synthetic business events.
