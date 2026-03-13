#!/usr/bin/env bash
# Example: Install Apache ZooKeeper 3.9.3 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/zookeeper-13.8.7-airgap.tar.gz"
RELEASE="zookeeper"
NAMESPACE="shared-apps"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Apache ZooKeeper..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "replicaCount=3" \
  --wait \
  -v

echo ""
echo "Done! ZooKeeper release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Connect to ZooKeeper:"
echo "  kubectl exec -it ${RELEASE}-0 -n ${NAMESPACE} -- zkCli.sh"
echo "  Service endpoint: ${RELEASE}.${NAMESPACE}.svc.cluster.local:2181"
