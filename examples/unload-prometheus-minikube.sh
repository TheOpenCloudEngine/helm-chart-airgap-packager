#!/usr/bin/env bash
# Uninstall Prometheus from minikube (reverse of load-prometheus-minikube.sh)
#
# Usage:
#   ./unload-prometheus-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="prometheus"
NAMESPACE="prometheus"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling Prometheus (release: $RELEASE, namespace: $NAMESPACE)..."
if helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
  helm uninstall "$RELEASE" -n "$NAMESPACE"
  echo "    Release '$RELEASE' uninstalled."
else
  echo "    Release '$RELEASE' not found, skipping."
fi

# ── Delete namespace ───────────────────────────────────────────────────────────
echo ""
echo "==> Deleting namespace: $NAMESPACE..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo ""
echo "Done! Prometheus removed from minikube."
