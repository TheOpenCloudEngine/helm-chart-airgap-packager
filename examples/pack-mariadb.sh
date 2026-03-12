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

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/mariadb-11.5.7-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing MariaDB 10.6.12 (chart 11.5.7)..."
helm-airgap pack mariadb \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 11.5.7 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/mariadb-11.5.7" \
  --include-image bitnami/mariadb:10.6.12 \
  --include-image bitnami/os-shell:12 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
