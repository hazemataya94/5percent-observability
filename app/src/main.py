import logging
import os
import random
import time
from http import HTTPStatus
from typing import Any

from flask import Flask, Response, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest


logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(asctime)s %(levelname)s %(name)s %(message)s")
logger = logging.getLogger("fivepercent.sample_metrics_app")

REQUEST_COUNT = Counter(
    "fivepercent_http_requests_total",
    "Total HTTP requests handled by the sample app.",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "fivepercent_http_request_duration_seconds",
    "HTTP request duration for the sample app.",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5),
)
IN_PROGRESS = Gauge(
    "fivepercent_http_requests_in_progress",
    "HTTP requests currently in progress.",
)
BUSINESS_EVENTS = Counter(
    "fivepercent_business_events_total",
    "Synthetic business events produced by the sample app.",
    ["event_type"],
)

app = Flask(__name__)


@app.before_request
def before_request() -> None:
    g.start_time = time.perf_counter()
    IN_PROGRESS.inc()


@app.after_request
def after_request(response: Response) -> Response:
    endpoint = request.endpoint or "unknown"
    elapsed_seconds = time.perf_counter() - g.start_time
    REQUEST_LATENCY.labels(request.method, endpoint).observe(elapsed_seconds)
    REQUEST_COUNT.labels(request.method, endpoint, str(response.status_code)).inc()
    IN_PROGRESS.dec()
    return response


@app.errorhandler(Exception)
def handle_exception(error: Exception) -> tuple[Response, int]:
    logger.exception("Unhandled request error")
    payload = jsonify({"status": "error", "message": "internal server error"})
    return payload, HTTPStatus.INTERNAL_SERVER_ERROR


@app.get("/")
def index() -> dict[str, Any]:
    BUSINESS_EVENTS.labels("page_view").inc()
    return {
        "service": "fivepercent-observability-sample-app",
        "message": "Use /work to generate synthetic latency and /metrics for Prometheus metrics.",
    }


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/work")
def work() -> dict[str, Any]:
    event_type = random.choice(("signup", "checkout", "search"))
    latency_seconds = random.uniform(0.02, 0.4)
    time.sleep(latency_seconds)
    BUSINESS_EVENTS.labels(event_type).inc()
    return {
        "status": "ok",
        "event_type": event_type,
        "simulated_latency_seconds": round(latency_seconds, 3),
    }


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    port = int(os.getenv("APP_PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
