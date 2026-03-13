#!/usr/bin/env bash
# Example: Pack Grafana 12.4.1 (grafana/grafana chart 11.3.2) for airgap deployment
#
# Source command:
#   helm repo add grafana https://grafana.github.io/helm-charts
#   helm pull grafana/grafana --version 11.3.2
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/grafana-11.3.2-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull grafana/grafana:12.4.1"
echo ""
echo "==> Packing Grafana 12.4.1 (chart 11.3.2)..."
helm-airgap pack grafana \
  --repo-url https://grafana.github.io/helm-charts \
  --repo-name opencloudengine \
  --chart-version 11.3.2 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/grafana-11.3.2" \
  --include-image grafana/grafana:12.4.1 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
