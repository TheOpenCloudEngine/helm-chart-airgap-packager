#!/usr/bin/env bash
# Example: Install PostgreSQL 16.4.0 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000
set -euo pipefail

BUNDLE="./bundles/postgresql-15.5.38-airgap.tar.gz"
RELEASE="postgresql"
NAMESPACE="database"
REGISTRY="myregistry.local:5000"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing PostgreSQL..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "auth.postgresPassword=changeme" \
  --set "auth.database=mydb" \
  --set "primary.persistence.size=10Gi" \
  --wait \
  -v

echo ""
echo "Done! PostgreSQL release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Connect to PostgreSQL:"
echo "  kubectl exec -it ${RELEASE}-0 -n ${NAMESPACE} -- psql -U postgres"
echo "  Service endpoint: ${RELEASE}.${NAMESPACE}.svc.cluster.local:5432"
echo ""
echo "Retrieve password:"
echo "  kubectl get secret ${RELEASE} -n ${NAMESPACE} -o jsonpath='{.data.postgres-password}' | base64 -d"
