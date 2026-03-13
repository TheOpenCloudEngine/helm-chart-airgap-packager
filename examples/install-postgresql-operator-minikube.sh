#!/usr/bin/env bash
# Install CloudNativePG operator 1.28.1 from chart saved by load-postgresql-operator-minikube.sh
# and create a PostgreSQL Cluster CRD instance.
#
# Usage:
#   ./install-postgresql-operator-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-postgresql-operator-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="cnpg"
NAMESPACE="shared-apps"
PG_CLUSTER_NAME="my-postgres"
PG_CLUSTER_NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "cloudnative-pg-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No cloudnative-pg chart .tgz found in $CHART_DIR"
  echo "       Run load-postgresql-operator-minikube.sh first."
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

# ── Create PostgreSQL Cluster CRD ─────────────────────────────────────────────
echo ""
echo "==> Creating PostgreSQL Cluster: $PG_CLUSTER_NAME (namespace: $PG_CLUSTER_NAMESPACE)..."
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${PG_CLUSTER_NAME}
  namespace: ${PG_CLUSTER_NAMESPACE}
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:17
  storage:
    size: 1Gi
EOF

echo ""
echo "==> Waiting for PostgreSQL cluster to be ready..."
kubectl wait --for=condition=Ready \
  cluster.postgresql.cnpg.io/${PG_CLUSTER_NAME} \
  -n "${PG_CLUSTER_NAMESPACE}" \
  --timeout=300s

echo ""
echo "Done! PostgreSQL cluster '${PG_CLUSTER_NAME}' is ready."
echo ""
echo "Connect to PostgreSQL:"
echo "  kubectl exec -it ${PG_CLUSTER_NAME}-1 -n ${PG_CLUSTER_NAMESPACE} -- psql -U postgres"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
