#!/usr/bin/env bash
# Load Prometheus 3.10.0 airgap bundle images into minikube and install
#
# Usage:
#   ./load-prometheus-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Bundle created by pack-prometheus.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/prometheus-28.13.0-airgap.tar.gz"
RELEASE="prometheus"
NAMESPACE="prometheus"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-prometheus.sh first."
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
echo "==> Installing Prometheus (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "server.image.pullPolicy=IfNotPresent" \
  --set "alertmanager.image.pullPolicy=IfNotPresent" \
  --set "kube-state-metrics.image.pullPolicy=IfNotPresent" \
  --set "prometheus-node-exporter.image.pullPolicy=IfNotPresent" \
  --set "prometheus-pushgateway.image.pullPolicy=IfNotPresent" \
  --set "server.persistentVolume.enabled=false" \
  --set "alertmanager.persistence.enabled=false" \
  --wait

echo ""
echo "Done! Prometheus release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Prometheus UI:"
echo "  kubectl port-forward svc/${RELEASE}-server 9090:80 -n ${NAMESPACE}"
echo "  URL: http://localhost:9090"
echo ""
echo "Access Alertmanager UI:"
echo "  kubectl port-forward svc/${RELEASE}-alertmanager 9093:9093 -n ${NAMESPACE}"
echo "  URL: http://localhost:9093"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
