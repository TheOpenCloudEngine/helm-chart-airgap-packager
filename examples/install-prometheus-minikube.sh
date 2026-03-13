#!/usr/bin/env bash
# Install Prometheus 3.10.0 from chart saved by load-prometheus-minikube.sh
#
# Usage:
#   ./install-prometheus-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-prometheus-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="prometheus"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "prometheus-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No prometheus chart .tgz found in $CHART_DIR"
  echo "       Run load-prometheus-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

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
