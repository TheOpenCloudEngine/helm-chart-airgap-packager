#!/usr/bin/env bash
# Example: Install Harbor 2.14.2 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000
#   - An ingress controller installed (or use expose.type=nodePort)

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/harbor-1.18.2-airgap.tar.gz"
RELEASE="harbor"
NAMESPACE="shared-apps"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Harbor 2.14.2..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "expose.type=ingress" \
  --set "expose.ingress.hosts.core=harbor.example.com" \
  --set "externalURL=https://harbor.example.com" \
  --set "harborAdminPassword=Harbor12345" \
  --set "persistence.persistentVolumeClaim.registry.size=50Gi" \
  --set "persistence.persistentVolumeClaim.jobservice.jobLog.size=5Gi" \
  --set "persistence.persistentVolumeClaim.database.size=5Gi" \
  --set "persistence.persistentVolumeClaim.redis.size=2Gi" \
  --set "persistence.persistentVolumeClaim.trivy.size=5Gi" \
  --wait \
  -v

echo ""
echo "Done! Harbor release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Harbor UI:"
echo "  https://harbor.example.com  (admin / Harbor12345)"
echo ""
echo "Login via Docker CLI:"
echo "  docker login harbor.example.com -u admin -p Harbor12345"
echo ""
echo "Retrieve admin password:"
echo "  kubectl get secret ${RELEASE}-core -n ${NAMESPACE} -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d"
