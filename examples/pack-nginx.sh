#!/usr/bin/env bash
# Example: Pack bitnami/nginx chart from the official Bitnami repo

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/nginx-15.14.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing nginx (chart 15.14.0)..."
helm-airgap pack nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 15.14.0 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR" \
  --include-image bitnami/nginx:1.25.3 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
