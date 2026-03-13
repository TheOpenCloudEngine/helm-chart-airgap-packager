#!/usr/bin/env bash
# Uninstall MariaDB Operator from minikube (reverse of load-mariadb-minikube.sh)
#
# Usage:
#   ./unload-mariadb-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="mariadb-operator"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling MariaDB Operator (release: $RELEASE, namespace: $NAMESPACE)..."
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
echo "Done! MariaDB Operator removed from minikube."
echo ""
echo "Note: MariaDB CRD instances in other namespaces are NOT removed."
echo "      To delete them: kubectl delete mariadbs.k8s.mariadb.com --all -A"

# ── Verify removal ────────────────────────────────────────────────────────────
echo ""
echo "==> Verifying removal (namespace '$NAMESPACE' should not exist):"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "    Namespace '$NAMESPACE' successfully removed."
