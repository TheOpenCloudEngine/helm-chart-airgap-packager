#!/usr/bin/env bash
# Example: Pack CloudNativePG operator 1.28.1 (cnpg/cloudnative-pg chart 0.27.1) for airgap deployment
#
# Source command:
#   helm repo add cnpg https://cloudnative-pg.github.io/charts
#   helm pull cnpg/cloudnative-pg --version 0.27.1
#
# Note: CloudNativePG (CNPG) is a Kubernetes operator for PostgreSQL.
#       After deploying the operator, create a Cluster CRD to provision PostgreSQL instances.
#       The postgresql image (ghcr.io/cloudnative-pg/postgresql:17) is used by Cluster resources.
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/cloudnative-pg-0.27.1-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull ghcr.io/cloudnative-pg/cloudnative-pg:1.28.1"
echo "  docker pull ghcr.io/cloudnative-pg/postgresql:17"
echo ""
echo "==> Packing CloudNativePG operator 1.28.1 (chart 0.27.1)..."
helm-airgap pack cloudnative-pg \
  --repo-url https://cloudnative-pg.github.io/charts \
  --repo-name cnpg \
  --chart-version 0.27.1 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/cloudnative-pg-0.27.1" \
  --include-image ghcr.io/cloudnative-pg/cloudnative-pg:1.28.1 \
  --include-image ghcr.io/cloudnative-pg/postgresql:17 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
