#!/usr/bin/env bash
# Install MariaDB Operator 25.10.4 from chart saved by load-mariadb-minikube.sh
#
# Usage:
#   ./install-mariadb-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Images loaded by load-mariadb-minikube.sh

set -euo pipefail

. "$(dirname "$0")/config.sh"

RELEASE="mariadb-operator"
NAMESPACE="shared-apps"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHART_DIR" -name "mariadb-operator-*.tgz" 2>/dev/null | sort -V | tail -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No mariadb-operator chart .tgz found in $CHART_DIR"
  echo "       Run load-mariadb-minikube.sh first."
  exit 1
fi

echo "==> Using chart: $CHART_TGZ"

# ── Helm install ──────────────────────────────────────────────────────────────
echo ""
echo "==> Installing MariaDB Operator (release: $RELEASE, namespace: $NAMESPACE)..."
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "image.pullPolicy=IfNotPresent" \
  --wait

echo ""
echo "Done! MariaDB Operator '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Create a MariaDB instance:"
echo "  kubectl create secret generic mariadb-secret --from-literal=password=changeme"
echo ""
echo "  kubectl apply -f - <<EOF"
echo "  apiVersion: k8s.mariadb.com/v1alpha1"
echo "  kind: MariaDB"
echo "  metadata:"
echo "    name: my-mariadb"
echo "  spec:"
echo "    rootPasswordSecretKeyRef:"
echo "      name: mariadb-secret"
echo "      key: password"
echo "    image: mariadb:11.4"
echo "    imagePullPolicy: IfNotPresent"
echo "    storage:"
echo "      size: 1Gi"
echo "  EOF"
echo ""
echo "Connect to MariaDB:"
echo "  kubectl exec -it my-mariadb-0 -- mariadb -u root -p"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
