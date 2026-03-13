#!/usr/bin/env bash
# Load CloudNativePG operator 1.28.1 airgap bundle images into minikube and install
#
# Usage:
#   ./load-postgresql-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Bundle created by pack-postgresql.sh
#
# Note: This installs the CloudNativePG operator.
#       After installation, create a PostgreSQL cluster with a Cluster CRD, e.g.:
#         kubectl apply -f - <<EOF
#         apiVersion: postgresql.cnpg.io/v1
#         kind: Cluster
#         metadata:
#           name: my-postgres
#         spec:
#           instances: 1
#           storage:
#             size: 1Gi
#         EOF

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/cloudnative-pg-0.27.1-airgap.tar.gz"
RELEASE="cnpg"
NAMESPACE="cnpg-system"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-postgresql.sh first."
  exit 1
fi

# ── Extract bundle ─────────────────────────────────────────────────────────────
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

echo "==> Extracting bundle: $BUNDLE"
tar xzf "$BUNDLE" -C "$TMPDIR_WORK"

BUNDLE_DIR=$(find "$TMPDIR_WORK" -mindepth 1 -maxdepth 1 -type d | head -1)
IMAGES_DIR="$BUNDLE_DIR/images"
CHARTS_DIR="$BUNDLE_DIR/charts"

# ── Load images into minikube ─────────────────────────────────────────────────
echo ""
echo "==> Loading images into minikube..."
for img_tar in "$IMAGES_DIR"/*.tar; do
  [ -f "$img_tar" ] || continue
  echo "    $(basename "$img_tar")"
  minikube image load "$img_tar"
done
echo "    Images loaded."

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHARTS_DIR" -name "*.tgz" | head -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No chart .tgz found in bundle"
  exit 1
fi

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing CloudNativePG operator (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "config.imagePullPolicy=IfNotPresent" \
  --wait

echo ""
echo "Done! CloudNativePG operator '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Create a PostgreSQL cluster:"
echo "  kubectl apply -f - <<EOF"
echo "  apiVersion: postgresql.cnpg.io/v1"
echo "  kind: Cluster"
echo "  metadata:"
echo "    name: my-postgres"
echo "    namespace: default"
echo "  spec:"
echo "    instances: 1"
echo "    imageName: ghcr.io/cloudnative-pg/postgresql:17"
echo "    storage:"
echo "      size: 1Gi"
echo "  EOF"
echo ""
echo "Connect to PostgreSQL:"
echo "  kubectl exec -it my-postgres-1 -- psql -U postgres"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
