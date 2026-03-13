#!/usr/bin/env bash
# Install Keycloak 26.5.5 from chart saved by load-keycloak-minikube.sh
#
# Usage:
#   ./install-keycloak-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-keycloak-minikube.sh
#
# Note: Runs in dev mode (H2 in-memory DB), suitable for testing only.
#       For production, configure externalDatabase values.

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="keycloak"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "keycloakx-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No keycloakx chart .tgz found in $CHART_DIR"
  echo "       Run load-keycloak-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing Keycloak (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "image.pullPolicy=IfNotPresent" \
  --set "command[0]=start-dev" \
  --set "args=null" \
  --wait

echo ""
echo "Done! Keycloak release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Keycloak Admin Console:"
echo "  kubectl port-forward svc/${RELEASE}-http 8080:80 -n ${NAMESPACE}"
echo "  URL: http://localhost:8080/admin  (admin / admin)"
echo ""
echo "Note: Running in dev mode (H2 in-memory DB). For production, configure externalDatabase."

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
