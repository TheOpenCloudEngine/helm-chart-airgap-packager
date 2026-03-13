#!/usr/bin/env bash
# Uninstall Apache ZooKeeper from minikube (reverse of load-zookeeper-minikube.sh)
#
# Usage:
#   ./unload-zookeeper-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="zookeeper"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling ZooKeeper (release: $RELEASE, namespace: $NAMESPACE)..."
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
echo "Done! Apache ZooKeeper removed from minikube."

# ── Verify removal ────────────────────────────────────────────────────────────
echo ""
echo "==> Verifying removal (namespace '$NAMESPACE' should not exist):"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "    Namespace '$NAMESPACE' successfully removed."
