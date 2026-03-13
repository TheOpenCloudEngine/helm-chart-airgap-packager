#!/usr/bin/env bash
# Load NGINX Ingress Controller 1.15.0 airgap bundle images into minikube and install
#
# Usage:
#   ./load-nginx-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Bundle created by pack-nginx.sh
#
# Note: This installs the ingress-nginx controller.
#       On minikube, the controller service type is set to NodePort.
#       Access via: minikube service ingress-nginx-controller -n ingress-nginx

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/ingress-nginx-4.15.0-airgap.tar.gz"
RELEASE="ingress-nginx"
NAMESPACE="ingress-nginx"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-nginx.sh first."
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
echo "==> Installing NGINX Ingress Controller (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "controller.image.pullPolicy=IfNotPresent" \
  --set "controller.admissionWebhooks.patch.image.pullPolicy=IfNotPresent" \
  --set "controller.service.type=NodePort" \
  --wait

echo ""
echo "Done! NGINX Ingress Controller '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access ingress controller:"
echo "  minikube service ${RELEASE}-controller -n ${NAMESPACE} --url"
echo ""
echo "Enable minikube ingress addon (alternative):"
echo "  minikube addons enable ingress"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
