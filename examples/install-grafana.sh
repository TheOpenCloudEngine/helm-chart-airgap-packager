#!/usr/bin/env bash
# Example: Install Grafana 12.1.1 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/grafana-12.1.8-airgap.tar.gz"
RELEASE="grafana"
NAMESPACE="shared-apps"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Grafana..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "admin.password=changeme" \
  --set "persistence.size=5Gi" \
  --wait \
  -v

echo ""
echo "Done! Grafana release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Grafana UI:"
echo "  kubectl port-forward svc/${RELEASE} 3000:3000 -n ${NAMESPACE}"
echo "  URL: http://localhost:3000  (admin / changeme)"
echo ""
echo "Retrieve admin password:"
echo "  kubectl get secret ${RELEASE}-admin -n ${NAMESPACE} -o jsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d"
