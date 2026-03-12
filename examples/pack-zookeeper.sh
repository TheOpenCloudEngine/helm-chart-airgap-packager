#!/usr/bin/env bash
# Example: Pack Apache ZooKeeper 3.9.3 (Bitnami chart 13.8.7, OCI) for airgap deployment
#
# Source command:
#   helm pull oci://registry-1.docker.io/bitnamicharts/zookeeper --version 13.8.7
#
# Note: This chart is distributed via OCI registry, not a traditional Helm repo.
#
# Prerequisites:
#   - helm CLI installed (v3.8+ required for OCI support)
#   - docker or podman installed and running
set -euo pipefail

OUTPUT_DIR="./bundles"
BUNDLE="${OUTPUT_DIR}/zookeeper-13.8.7-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing Apache ZooKeeper 3.9.3 (chart 13.8.7, OCI)..."
helm-airgap pack oci://registry-1.docker.io/bitnamicharts/zookeeper \
  --chart-version 13.8.7 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
