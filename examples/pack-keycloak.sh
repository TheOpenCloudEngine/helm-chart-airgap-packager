#!/usr/bin/env bash
# Example: Pack Keycloak 26.5.5 (codecentric/keycloakx chart 7.1.9) for airgap deployment
#
# Source command:
#   helm repo add codecentric https://codecentric.github.io/helm-charts
#   helm pull codecentric/keycloakx --version 7.1.9
#
# Note: keycloakx uses the official Keycloak image from quay.io/keycloak/keycloak.
#       An external PostgreSQL database is required (configure via values.yaml).
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/keycloak-7.1.9-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull quay.io/keycloak/keycloak:26.5.5"
echo ""
echo "==> Packing Keycloak 26.5.5 (chart 7.1.9)..."
helm-airgap pack keycloakx \
  --repo-url https://codecentric.github.io/helm-charts \
  --repo-name opencloudengine \
  --chart-version 7.1.9 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/keycloak-7.1.9" \
  --include-image quay.io/keycloak/keycloak:26.5.5 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
