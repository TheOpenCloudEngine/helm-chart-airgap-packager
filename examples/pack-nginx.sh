#!/usr/bin/env bash
# Example: Pack bitnami/nginx chart from the official Bitnami repo

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/nginx-22.6.4-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull bitnami/nginx:1.29.6"
echo ""
echo "==> Packing nginx (chart 22.6.4)..."
helm-airgap pack nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 22.6.4 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/nginx-22.6.4" \
  --include-image bitnami/nginx:1.29.6 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
