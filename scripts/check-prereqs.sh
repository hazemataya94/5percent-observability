#!/usr/bin/env bash
set -euo pipefail

required_tools=(
  docker
  helm
  helmfile
  kind
  kubectl
)

missing_tools=()

for tool in "${required_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    missing_tools+=("${tool}")
  fi
done

if [ "${#missing_tools[@]}" -gt 0 ]; then
  echo "Missing required tools: ${missing_tools[*]}"
  echo "Install the missing tools, then run make check-prereqs again."
  exit 1
fi

echo "All required tools are available."
