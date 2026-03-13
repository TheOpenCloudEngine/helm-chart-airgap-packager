#!/usr/bin/env bash
# Example: Pack Apache ZooKeeper 3.6.3 via Confluent Platform 7.3.0 (rhcharts/zookeeper chart 0.2.0) for airgap deployment
#
# Source command:
#   helm repo add rhcharts https://ricardo-aires.github.io/helm-charts/
#   helm pull rhcharts/zookeeper --version 0.2.0
#
# Note: This chart deploys an Apache ZooKeeper ensemble using the Confluent Platform ZooKeeper image,
#       which is based on Apache ZooKeeper 3.6.3. Minimum 3 replicas are required for fault tolerance.
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/zookeeper-0.2.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull confluentinc/cp-zookeeper:7.3.0"
echo ""
echo "==> Packing Apache ZooKeeper 3.6.3 / Confluent Platform 7.3.0 (chart 0.2.0)..."
helm-airgap pack zookeeper \
  --repo-url https://ricardo-aires.github.io/helm-charts/ \
  --repo-name opencloudengine \
  --chart-version 0.2.0 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/zookeeper-0.2.0" \
  --include-image confluentinc/cp-zookeeper:7.3.0 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
