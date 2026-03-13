#!/usr/bin/env bash
# Install Apache ZooKeeper 3.6.3 from chart saved by load-zookeeper-minikube.sh
#
# Usage:
#   ./install-zookeeper-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-zookeeper-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="zookeeper"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "zookeeper-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No zookeeper chart .tgz found in $CHART_DIR"
  echo "       Run load-zookeeper-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing ZooKeeper (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "imagePullPolicy=IfNotPresent" \
  --set "replicaCount=1" \
  --wait

echo ""
echo "Done! ZooKeeper release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Connect to ZooKeeper (zkCli):"
echo "  kubectl exec -it ${RELEASE}-0 -n ${NAMESPACE} -- zookeeper-shell localhost:2181"
echo "  Service endpoint: ${RELEASE}.${NAMESPACE}.svc.cluster.local:2181"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
