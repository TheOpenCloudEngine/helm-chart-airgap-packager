#!/usr/bin/env bash
# Uninstall NGINX Ingress Controller from minikube (reverse of load-nginx-minikube.sh)
#
# Usage:
#   ./unload-nginx-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="ingress-nginx"
NAMESPACE="ingress-nginx"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling NGINX Ingress Controller (release: $RELEASE, namespace: $NAMESPACE)..."
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
echo "Done! NGINX Ingress Controller removed from minikube."

# ── Verify removal ────────────────────────────────────────────────────────────
echo ""
echo "==> Verifying removal (namespace '$NAMESPACE' should not exist):"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "    Namespace '$NAMESPACE' successfully removed."
