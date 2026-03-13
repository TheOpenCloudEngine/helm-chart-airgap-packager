#!/usr/bin/env bash
# Load Grafana 12.4.1 airgap bundle images into minikube and install
#
# Usage:
#   ./load-grafana-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Bundle created by pack-grafana.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/grafana-11.3.2-airgap.tar.gz"
RELEASE="grafana"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-grafana.sh first."
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
echo "==> Installing Grafana (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "adminPassword=changeme" \
  --set "image.pullPolicy=IfNotPresent" \
  --set "persistence.enabled=false" \
  --wait

echo ""
echo "Done! Grafana release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Grafana UI:"
echo "  kubectl port-forward svc/${RELEASE} 3000:80 -n ${NAMESPACE}"
echo "  URL: http://localhost:3000  (admin / changeme)"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
