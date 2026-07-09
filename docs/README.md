# 5percent Observability Lab Docs

## Purpose
These docs support a hands-on observability session using local Kubernetes, Prometheus, Grafana, Alertmanager, and an optional Loki appendix.

## Documentation Index
- `architecture.md` explains the lab components and runtime flow.
- `brainstorming.md` captures early notes, assumptions, open questions, and the first draft session plan.
- `session-plan.md` provides a phased teaching agenda.
- `validation.md` lists checks for the lab.
- `runbooks/README.md` provides local operations and rollback steps.
- `appendices/logging-with-loki.md` explains the optional logging extension.
- `appendices/alerting-with-alertmanager.md` explains the optional alerting extension.
- `llm/README.md` records repository-specific guidance for agents working in this lab.

## Local-Only Boundary
All commands are designed for a local `kind` cluster.
Do not point this lab at a remote Kubernetes cluster unless the session owner explicitly changes the scope.
