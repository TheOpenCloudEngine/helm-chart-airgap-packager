#!/usr/bin/env bash
# Uninstall Harbor from minikube (reverse of load-harbor-minikube.sh)
#
# Usage:
#   ./unload-harbor-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="harbor"
NAMESPACE="harbor"
HARBOR_HOSTNAME="harbor.local"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running."
  echo "       Start with: minikube start --memory=4096 --cpus=2"
  exit 1
fi

# ── Helm uninstall ─────────────────────────────────────────────────────────────
echo "==> Uninstalling Harbor (release: $RELEASE, namespace: $NAMESPACE)..."
if helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
  helm uninstall "$RELEASE" -n "$NAMESPACE"
  echo "    Release '$RELEASE' uninstalled."
else
  echo "    Release '$RELEASE' not found, skipping."
fi

# ── Delete PVCs ────────────────────────────────────────────────────────────────
# Harbor PVCs are not deleted by helm uninstall (retain policy)
echo ""
echo "==> Deleting PersistentVolumeClaims in namespace: $NAMESPACE..."
kubectl delete pvc --all -n "$NAMESPACE" --ignore-not-found

# ── Delete namespace ───────────────────────────────────────────────────────────
echo ""
echo "==> Deleting namespace: $NAMESPACE..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo ""
echo "Done! Harbor removed from minikube."
echo ""
echo "==> Remove the /etc/hosts entry if it was added:"
echo "    sudo sed -i '/${HARBOR_HOSTNAME}/d' /etc/hosts"
