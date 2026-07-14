IDEAS - ABD & Hazem

Homework 2 options:
- on the same repo: implement a form app, and create a metric of how many forms are submitted.
- find a needed metric in your workplace and implement observability for this metric.

---

# Observability Session Brainstorming

## Purpose
Capture early notes for the 5percent observability session before turning the material into a tighter teaching plan.
This document is intentionally draft-like and should evolve as the session goals, timing, and audience expectations become clearer.

## Audience
The audience is a group of software engineers.
They are expected to understand application development and basic service behavior, but they are beginners in observability.

Assumptions:
- They may have seen logs before, but may not know how metrics, logs, and alerts fit together.
- They may not have used Prometheus, Grafana, Alertmanager, Loki, or `ServiceMonitor` resources before.
- They should leave with a practical mental model, not a production monitoring architecture.

## First Planning Decisions
These decisions came from the first clarification pass.

- Session duration: 90 minutes.
- Delivery style: hands-on local lab where learners run the project themselves.
- Main depth: metrics and Grafana dashboard reading.
- Sample app language: keep Python.

## Second Planning Decisions
These decisions came from the deeper planning pass.

- Setup is useful, but not mandatory for every learner.
- The presenter can run the setup live while learners follow along if their laptops are ready.
- Learners should be able to run commands, but the session should also explain what each output means.
- The delivery style should be discussion-heavy rather than command-heavy.
- Include a short Kubernetes refresher before the observability flow.
- Include a beginner glossary.
- Keep SLI and SLO material conceptual.
- Do not include a required failure scenario in the main flow.
- Allow one optional alert trigger at the end if time allows.
- Treat the full Loki pipeline as a follow-up topic.
- Add an individual homework exercise.
- The one-sentence takeaway is: learners should be able to design a basic observability system.

## Main Topic
The main topic is metrics.
The session should spend most of its time on how applications expose metrics, how Prometheus collects them, and how Grafana turns them into useful dashboards.

Core idea:
> Metrics are numeric signals over time that help us understand the behavior and health of a system.

Beginner framing:
- What is happening right now?
- How often is it happening?
- How long does it take?
- Is it getting better or worse over time?
- What changed when users or traffic changed?

## Secondary Topics
Logging and alerting should be mentioned as secondary topics.
They can be taught mostly from documents, short examples, and discussion instead of being the main hands-on flow.

Logging:
- Logs are event records.
- Logs help explain what happened around a specific request or failure.
- Loki can be introduced as a log aggregation system that works well with Grafana.
- The first version can show `kubectl logs` and explain why centralized logging becomes useful later.

Alerting:
- Alerts turn metrics into action.
- Prometheus evaluates alert rules.
- Alertmanager groups, silences, and routes alerts.
- The first version can show one simple alert, such as the sample app being down.

## Example To Build Around
The practical example should be a small application that exposes Prometheus metrics and a Grafana dashboard that visualizes them.

The current lab already supports this flow:
- A sample app exposes `/metrics`.
- Prometheus discovers the app through a `ServiceMonitor`.
- Grafana loads a dashboard through a dashboard ConfigMap.
- The dashboard shows request rate, p95 latency, synthetic business events, and scrape target health.

Suggested dashboard story:
1. Start with the app running and no traffic.
2. Generate traffic with repeated calls to `/` and `/work`.
3. Open Prometheus and query raw metric series.
4. Open Grafana and show the same signals as charts.
5. Connect the charts to operational questions:
   - Are requests arriving?
   - Is latency acceptable?
   - Are business events increasing?
   - Is Prometheus scraping the app successfully?

## Draft Session Plan v0.3
This is a deeper draft for a 90-minute beginner session.
The plan is discussion-heavy and uses the lab as a concrete example rather than making the terminal the whole session.

### Learning Outcome
By the end of the session, learners should be able to design a basic observability system for a service.
They should be able to name the core metrics, explain how those metrics are collected, choose useful dashboard panels, and propose one or two actionable alerts.

### Delivery Model
The presenter runs the setup live.
Learners can follow along if their laptops are ready, but local setup is not required for learning.

The session should support both modes:
- Learners who run commands should understand what the command does and what output to expect.
- Learners who only watch should still be able to answer the dashboard and design questions.

### Timebox
| Segment | Time | Mode |
| --- | ---: | --- |
| Opening and goal | 5 min | Discussion |
| Glossary and Kubernetes refresher | 10 min | Explanation |
| Observability mental model | 10 min | Discussion |
| Local architecture and setup | 15 min | Presenter-led demo |
| Metrics concepts | 15 min | Explanation with examples |
| Individual dashboard reading exercise | 20 min | Individual exercise |
| Alerting walkthrough and optional trigger | 10 min | Demo or optional exercise |
| Wrap-up and homework | 5 min | Discussion |

## Detailed Flow
### 1. Opening And Goal
Goal: set a practical reason for observability.

Prompt:
> How do we know if a service is healthy, slow, overloaded, or failing?

Teaching notes:
- Observability is not only tooling.
- Observability is the ability to understand a running system from its external signals.
- The session focuses on metrics first because metrics are the easiest signal to aggregate, chart, and alert on.

Expected learner takeaway:
- The purpose of the session is to learn how to design basic observability for a service.

### 2. Glossary And Kubernetes Refresher
Goal: remove vocabulary blockers before the lab starts.

Keep the Kubernetes refresher short:
- Pod: runs the application container.
- Service: gives stable network access to pods.
- Namespace: groups related resources.
- Deployment: keeps the desired number of app replicas running.
- ConfigMap: stores non-secret configuration, such as a Grafana dashboard JSON.
- CustomResourceDefinition: lets Kubernetes support extra resource types.
- ServiceMonitor: tells Prometheus which Service to scrape.
- PrometheusRule: stores alerting or recording rules for Prometheus.

Beginner observability glossary:
- Metric: a numeric measurement over time.
- Time series: a stream of metric samples with the same metric name and labels.
- Label: a key-value dimension attached to a metric.
- Scrape: Prometheus pulling metrics from a target.
- Target: an endpoint Prometheus scrapes.
- Dashboard: a visual collection of queries and panels.
- Alert: a rule that turns a condition into a notification path.
- Counter: a metric that only increases, such as total requests.
- Gauge: a metric that can go up or down, such as in-progress requests.
- Histogram: a metric that groups observations into buckets, such as request duration.
- SLI: a service-level indicator, which is a measured reliability signal.
- SLO: a service-level objective, which is a target for an SLI.

Expected learner takeaway:
- The terms in the lab are familiar enough to follow the rest of the session.

### 3. Observability Mental Model
Goal: explain how metrics, logs, and alerts fit together.

Core framing:
- Metrics answer numeric questions over time.
- Logs explain details around events.
- Alerts identify conditions that need attention.
- Traces show request flow across services, but traces are out of scope for this first session.

Discussion prompt:
> If a user says the app is slow, which signal would you check first and why?

Expected learner takeaway:
- Metrics are the starting point for this session, but they do not replace logs or alerts.

### 4. Local Architecture And Setup
Goal: connect the lab components to the observability flow.

Presenter setup commands:
```bash
make check-prereqs
make kind-up
make monitoring-up
make app-up
make dashboard-up
```

Architecture story:
```text
sample app /metrics -> Service -> ServiceMonitor -> Prometheus -> Grafana dashboard
```

Teaching notes:
- The app exposes metrics.
- The Service gives Prometheus a stable scrape target.
- The ServiceMonitor tells Prometheus what to scrape.
- Prometheus stores and queries metrics.
- Grafana visualizes Prometheus queries.
- Alertmanager is available for alert routing.

Expected learner takeaway:
- Learners can explain the path from application metric to dashboard panel.

### 5. Metrics Concepts
Goal: teach the minimum concepts needed to read the dashboard and design basic metrics.

Counter:
- Use for totals that only go up.
- Example: `fivepercent_http_requests_total`.
- Common query pattern: use `rate()` to convert a counter into activity over time.

Gauge:
- Use for values that can increase and decrease.
- Example: `fivepercent_http_requests_in_progress`.
- Useful for current state or saturation-like signals.

Histogram:
- Use for distributions, especially latency.
- Example: `fivepercent_http_request_duration_seconds`.
- Common query pattern: use `histogram_quantile()` for p95 or p99 latency.

Golden signals:
- Traffic: how much work the service receives.
- Errors: how much work fails.
- Latency: how long work takes.
- Saturation: how full or busy the system is.

SLI and SLO:
- Keep this conceptual.
- An SLI is the signal we measure.
- An SLO is the target we want that signal to meet.
- Example: p95 request latency is under a chosen threshold for most of the time.

Expected learner takeaway:
- Learners can map common service questions to metric types and dashboard panels.

### 6. Individual Dashboard Reading Exercise
Goal: let each learner practice reading a dashboard as an engineer.

Presenter commands:
```bash
make grafana-port-forward
```

Learners inspect the `5percent Sample Metrics App` dashboard.

Individual questions:
1. Is the app receiving traffic?
2. Is Prometheus scraping the app successfully?
3. What does the p95 latency panel tell you?
4. Which panel would you check first if a user reports slowness?
5. Which panel would you check first if you suspect the app is not being monitored?
6. Which metric would you use for a basic alert?
7. What is missing from this dashboard if this were a real service?
8. Which golden signal is best covered by the current dashboard?
9. Which golden signal is weakest or missing?
10. What would you add before trusting this dashboard in production?

Group discussion after the individual exercise:
- Compare answers.
- Identify which panels answer operational questions.
- Identify which panels are interesting but not actionable.

Expected learner takeaway:
- Learners can read a dashboard and identify gaps in it.

### 7. Alerting Walkthrough And Optional Trigger
Goal: explain alerting as a design choice, not just a technical rule.

Main walkthrough:
- Show the sample `PrometheusRule`.
- Explain `expr`, `for`, `labels`, and `annotations`.
- Explain why alerts should be actionable.
- Explain alert fatigue.

Optional trigger if time allows:
```bash
make alerts-up
make alertmanager-port-forward
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deploy/sample-metrics-app --replicas=0
kubectl --context kind-fivepercent-observability -n fivepercent-observability scale deploy/sample-metrics-app --replicas=2
```

Teaching note:
- The optional trigger should happen only if the group has enough time and the lab is stable.
- The main learning objective is understanding alert design, not forcing a live incident exercise.

Expected learner takeaway:
- Learners can propose a basic alert and explain why it is actionable.

### 8. Logging And Loki As Follow-Up
Goal: place logging in the system without making it core to this session.

Notes:
- Logs are useful after metrics point to a symptom.
- `kubectl logs` is enough for the first explanation.
- Loki and log collection can become a follow-up session.
- Full Loki setup should not consume time in the 90-minute metrics-first session.

Possible quick example:
```bash
kubectl --context kind-fivepercent-observability -n fivepercent-observability logs deploy/sample-metrics-app
```

Expected learner takeaway:
- Learners know why logs matter, but understand that the session is metrics-first.

### 9. Wrap-Up And Homework
Goal: move from reading this lab to designing observability for another service.

Wrap-up prompt:
> If you owned this service, what would you monitor first?

Homework:
Choose one service you know and design its basic observability system.

The homework answer should include:
- Service name and purpose.
- Three to five key metrics.
- The metric type for each metric: counter, gauge, or histogram.
- Which golden signal each metric supports.
- Three dashboard panels.
- One or two alerts.
- What logs would help investigate problems.
- One conceptual SLI.
- One conceptual SLO.

Expected learner takeaway:
- Learners can apply the same design process to their own services.

## Draft Acceptance Criteria
The plan is ready for a more formal `session-plan.md` update when it satisfies these criteria:
- The 90-minute flow has clear timing.
- The presenter can run the session even if learner setup fails.
- Each section has a concrete learner outcome.
- The dashboard exercise is individual and answerable from the current Grafana dashboard.
- SLI and SLO stay conceptual.
- Loki is clearly marked as a follow-up topic.
- Alert triggering is optional and reversible.
- Homework asks learners to design a basic observability system.

## Remaining Planning Questions
1. Should the presenter prepare screenshots in case Grafana setup is slow?
2. Should the homework be submitted, discussed, or just used for self-study?
3. Should the dashboard exercise have an answer key?
4. Should we add an explicit pre-session setup checklist even though setup is optional?
5. Should the final formal plan live in `session-plan.md`, or should `brainstorming.md` remain the only planning document for now?
