#!/usr/bin/env bash
# Install Apache Airflow 3.1.7 from chart saved by load-airflow-minikube.sh
#
# Usage:
#   ./install-airflow-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-airflow-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="airflow"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "airflow-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No airflow chart .tgz found in $CHART_DIR"
  echo "       Run load-airflow-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing Apache Airflow (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "postgresql.image.repository=postgres" \
  --set-string "postgresql.image.tag=17" \
  --set "defaultAirflowTag=3.1.7" \
  --set "global.imagePullPolicy=IfNotPresent" \
  --timeout 10m \
  --wait

echo ""
echo "Done! Airflow release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access the Airflow Web UI:"
echo "  kubectl port-forward svc/${RELEASE}-webserver 8080:8080 -n ${NAMESPACE}"
echo "  URL: http://localhost:8080  (admin / admin)"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
