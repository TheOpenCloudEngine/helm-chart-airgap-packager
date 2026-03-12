#!/usr/bin/env bash
# Example: Install Keycloak 26.3.3 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000
set -euo pipefail

BUNDLE="./bundles/keycloak-25.2.0-airgap.tar.gz"
RELEASE="keycloak"
NAMESPACE="keycloak"
REGISTRY="myregistry.local:5000"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Keycloak..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "auth.adminUser=admin" \
  --set "auth.adminPassword=changeme" \
  --wait \
  -v

echo ""
echo "Done! Keycloak release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access the Keycloak Admin Console:"
echo "  kubectl port-forward svc/${RELEASE} 8080:80 -n ${NAMESPACE}"
echo "  URL: http://localhost:8080/admin  (admin / changeme)"
