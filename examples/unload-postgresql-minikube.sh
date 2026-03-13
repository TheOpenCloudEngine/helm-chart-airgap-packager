#!/usr/bin/env bash
# Uninstall CloudNativePG operator from minikube (reverse of load-postgresql-minikube.sh)
#
# Usage:
#   ./unload-postgresql-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="cnpg"
NAMESPACE="cnpg-system"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling CloudNativePG operator (release: $RELEASE, namespace: $NAMESPACE)..."
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
echo "Done! CloudNativePG operator removed from minikube."
echo ""
echo "Note: Cluster CRDs and any Cluster resources in other namespaces are NOT removed."
echo "      To delete them: kubectl delete clusters.postgresql.cnpg.io --all -A"
