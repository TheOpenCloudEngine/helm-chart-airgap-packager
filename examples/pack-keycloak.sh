#!/usr/bin/env bash
# Example: Pack Keycloak 26.3.3 (Bitnami chart 25.2.0, OCI) for airgap deployment
#
# Source command:
#   helm pull oci://registry-1.docker.io/bitnamicharts/keycloak --version 25.2.0
#
# Note: This chart is distributed via OCI registry, not a traditional Helm repo.
#
# Prerequisites:
#   - helm CLI installed (v3.8+ required for OCI support)
#   - docker or podman installed and running

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/keycloak-25.2.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing Keycloak 26.3.3 (chart 25.2.0, OCI)..."
helm-airgap pack oci://registry-1.docker.io/bitnamicharts/keycloak \
  --chart-version 25.2.0 \
  --chart-dir "$CHART_DIR" \
  --include-image bitnami/keycloak:26.3.3 \
  --include-image bitnami/os-shell:12 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
