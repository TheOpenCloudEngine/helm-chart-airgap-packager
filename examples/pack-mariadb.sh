#!/usr/bin/env bash
# Example: Pack MariaDB Operator 25.10.4 (mariadb-operator/mariadb-operator chart 25.10.4) for airgap deployment
#
# Source command:
#   helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operator
#   helm pull mariadb-operator/mariadb-operator --version 25.10.4
#
# Note: mariadb-operator is the official Kubernetes operator for MariaDB.
#       After deploying the operator, create MariaDB CRDs to provision instances.
#       The mariadb server image (mariadb:11.4) is used by MariaDB resources.
#       Also install CRDs first: helm install mariadb-operator-crds mariadb-operator/mariadb-operator-crds
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/mariadb-operator-25.10.4-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull ghcr.io/mariadb-operator/mariadb-operator:25.10.4"
echo "  docker pull mariadb:11.4"
echo ""
echo "==> Packing MariaDB Operator 25.10.4 (chart 25.10.4)..."
helm-airgap pack mariadb-operator \
  --repo-url https://helm.mariadb.com/mariadb-operator \
  --repo-name opencloudengine \
  --chart-version 25.10.4 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/mariadb-operator-25.10.4" \
  --include-image ghcr.io/mariadb-operator/mariadb-operator:25.10.4 \
  --include-image mariadb:11.4 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
