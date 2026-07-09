# LLM Guidance

## Purpose
This file captures guidance specific to the 5percent observability lab.

## Rules
- Keep examples local-only and based on `kind`.
- Do not add cloud, remote cluster, or production deployment steps without explicit approval.
- Do not add secrets or organization-specific values.
- Keep Kubernetes manifests compatible with the local rule that forbids CPU limits.
- Prefer Makefile, Helmfile, and Kustomize patterns already used in this lab.
- Keep learning docs concise and executable from `hape-academy/5percent/observability`.
