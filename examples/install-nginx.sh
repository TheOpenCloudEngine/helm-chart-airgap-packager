#!/usr/bin/env bash
# Example: Install nginx from a bundle into an airgap cluster
#
# Prerequisites (on airgap machine):
#   - docker or podman
#   - helm
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

BUNDLE="./bundles/nginx-15.14.0-airgap.tar.gz"
RELEASE="my-nginx"
NAMESPACE="web"
REGISTRY="myregistry.local:5000"

# Inspect the bundle first
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --wait \
  -v

echo ""
echo "Done! Release '$RELEASE' deployed in namespace '$NAMESPACE'."
