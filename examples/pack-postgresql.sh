#!/usr/bin/env bash
# Example: Pack PostgreSQL 16.4.0 (Bitnami chart 15.5.38) for airgap deployment
#
# Source command:
#   helm repo add bitnami https://charts.bitnami.com/bitnami
#   helm pull bitnami/postgresql --version 15.5.38
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

OUTPUT_DIR="./bundles"
BUNDLE="${OUTPUT_DIR}/postgresql-15.5.38-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing PostgreSQL 16.4.0 (chart 15.5.38)..."
helm-airgap pack postgresql \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 15.5.38 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
