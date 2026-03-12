#!/usr/bin/env bash
# Example: Pack MariaDB 10.6.12 (Bitnami chart 11.5.7) for airgap deployment
#
# Source command:
#   helm repo add bitnami https://charts.bitnami.com/bitnami
#   helm pull bitnami/mariadb --version 11.5.7
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running
set -euo pipefail

OUTPUT_DIR="./bundles"
BUNDLE="${OUTPUT_DIR}/mariadb-11.5.7-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing MariaDB 10.6.12 (chart 11.5.7)..."
helm-airgap pack mariadb \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 11.5.7 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
