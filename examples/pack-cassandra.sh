#!/usr/bin/env bash
# Example: Pack Apache Cassandra 5.0.5 (Bitnami chart 12.3.11, OCI) for airgap deployment
#
# Source command:
#   helm pull oci://registry-1.docker.io/bitnamicharts/cassandra --version 12.3.11
#
# Note: This chart is distributed via OCI registry, not a traditional Helm repo.
#
# Prerequisites:
#   - helm CLI installed (v3.8+ required for OCI support)
#   - docker or podman installed and running

OUTPUT_DIR="./bundles"
BUNDLE="${OUTPUT_DIR}/cassandra-12.3.11-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing Apache Cassandra 5.0.5 (chart 12.3.11, OCI)..."
helm-airgap pack oci://registry-1.docker.io/bitnamicharts/cassandra \
  --chart-version 12.3.11 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
