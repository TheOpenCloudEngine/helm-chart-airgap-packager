#!/usr/bin/env bash
# Install Grafana 12.4.1 from chart saved by load-grafana-minikube.sh
#
# Usage:
#   ./install-grafana-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-grafana-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="grafana"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "grafana-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No grafana chart .tgz found in $CHART_DIR"
  echo "       Run load-grafana-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

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
