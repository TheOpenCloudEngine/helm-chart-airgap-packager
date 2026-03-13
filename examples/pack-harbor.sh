#!/usr/bin/env bash
# Example: Pack bitnami/nginx chart from the official Bitnami repo

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/harbor-1.18.2-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing harbor (chart 1.18.2)..."
helm-airgap pack harbor \
  --repo-url https://helm.goharbor.io \
  --repo-name harbor \
  --chart-version 1.18.2 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/harbor-2.14.2" \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
