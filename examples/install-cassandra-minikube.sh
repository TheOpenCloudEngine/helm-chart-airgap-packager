#!/usr/bin/env bash
# Install K8ssandra Operator 1.29.0 (Cassandra 5.0) from chart saved by load-cassandra-minikube.sh
#
# Usage:
#   ./install-cassandra-minikube.sh
#
# Prerequisites:
#   - minikube running with enough resources (minikube start --memory=4096 --cpus=2)
#   - helm CLI installed
#   - Images loaded by load-cassandra-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="k8ssandra-operator"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start --memory=4096 --cpus=2"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "k8ssandra-operator-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No k8ssandra-operator chart .tgz found in $CHART_DIR"
  echo "       Run load-cassandra-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing K8ssandra Operator (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "image.pullPolicy=IfNotPresent" \
  --wait

echo ""
echo "Done! K8ssandra Operator '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Create a Cassandra cluster:"
echo "  kubectl apply -f - <<EOF"
echo "  apiVersion: k8ssandra.io/v1alpha1"
echo "  kind: K8ssandraCluster"
echo "  metadata:"
echo "    name: my-cassandra"
echo "  spec:"
echo "    cassandra:"
echo "      serverVersion: \"5.0.2\""
echo "      storageConfig:"
echo "        cassandraDataVolumeClaimSpec:"
echo "          storageClassName: standard"
echo "          accessModes: [ReadWriteOnce]"
echo "          resources:"
echo "            requests:"
echo "              storage: 5Gi"
echo "      datacenters:"
echo "        - metadata:"
echo "            name: dc1"
echo "          size: 1"
echo "  EOF"
echo ""
echo "Connect to Cassandra (cqlsh):"
echo "  kubectl exec -it my-cassandra-dc1-default-sts-0 -n default -- cqlsh"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
