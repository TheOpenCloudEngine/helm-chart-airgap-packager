#!/usr/bin/env bash
# Example: Install Apache Cassandra 5.0.5 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/cassandra-12.3.11-airgap.tar.gz"
RELEASE="cassandra"
NAMESPACE="shared-apps"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Apache Cassandra..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "dbUser.password=changeme" \
  --set "replicaCount=3" \
  --set "persistence.size=10Gi" \
  --wait \
  -v

echo ""
echo "Done! Cassandra release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Connect to Cassandra (cqlsh):"
echo "  kubectl exec -it ${RELEASE}-0 -n ${NAMESPACE} -- cqlsh -u cassandra -p changeme"
echo "  Service endpoint: ${RELEASE}.${NAMESPACE}.svc.cluster.local:9042"
