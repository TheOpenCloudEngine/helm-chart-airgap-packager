#!/usr/bin/env bash
# Example: Install Prometheus 3.10.0 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000
set -euo pipefail

BUNDLE="./bundles/prometheus-28.13.0-airgap.tar.gz"
RELEASE="prometheus"
NAMESPACE="monitoring"
REGISTRY="myregistry.local:5000"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Prometheus..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "server.persistentVolume.size=20Gi" \
  --set "alertmanager.persistence.size=5Gi" \
  --wait \
  -v

echo ""
echo "Done! Prometheus release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access Prometheus UI:"
echo "  kubectl port-forward svc/${RELEASE}-server 9090:80 -n ${NAMESPACE}"
echo "  URL: http://localhost:9090"
echo ""
echo "Access Alertmanager UI:"
echo "  kubectl port-forward svc/${RELEASE}-alertmanager 9093:9093 -n ${NAMESPACE}"
echo "  URL: http://localhost:9093"
