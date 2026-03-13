#!/usr/bin/env bash
# Install CloudNativePG operator 1.28.1 from chart saved by load-postgresql-minikube.sh
#
# Usage:
#   ./install-postgresql-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-postgresql-minikube.sh
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
#         kubectl get pods -n shared-apps -w
#         kubectl get pods -n shared-apps
#         kubectl exec -it my-postgres-1 -n shared-apps -- psql -U postgres


set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="postgresql"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "cloudnative-pg-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No cloudnative-pg chart .tgz found in $CHART_DIR"
  echo "       Run load-postgresql-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

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
