#!/usr/bin/env bash
# Example: Pack Grafana 12.1.1 (Bitnami chart 12.1.8, OCI) for airgap deployment
#
# Source command:
#   helm pull oci://registry-1.docker.io/bitnamicharts/grafana --version 12.1.8
#
# Note: This chart is distributed via OCI registry, not a traditional Helm repo.
#
# Prerequisites:
#   - helm CLI installed (v3.8+ required for OCI support)
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/grafana-12.1.8-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull bitnami/grafana:12.1.1"
echo "  docker pull bitnami/os-shell:12"
echo ""
echo "==> Packing Grafana 12.1.1 (chart 12.1.8, OCI)..."
helm-airgap pack oci://registry-1.docker.io/bitnamicharts/grafana \
  --chart-version 12.1.8 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/grafana-12.1.8" \
  --include-image bitnami/grafana:12.1.1 \
  --include-image bitnami/os-shell:12 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
