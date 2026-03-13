#!/usr/bin/env bash
# Install NGINX Ingress Controller 1.15.0 from chart saved by load-nginx-minikube.sh
#
# Usage:
#   ./install-nginx-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-nginx-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="ingress-nginx"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "ingress-nginx-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No ingress-nginx chart .tgz found in $CHART_DIR"
  echo "       Run load-nginx-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

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
