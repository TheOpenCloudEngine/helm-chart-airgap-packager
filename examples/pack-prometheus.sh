#!/usr/bin/env bash
# Example: Pack Prometheus 3.10.0 (prometheus-community chart 28.13.0) for airgap deployment
#
# Source command:
#   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#   helm pull prometheus-community/prometheus --version 28.13.0
#
# Note: The Prometheus chart includes multiple sub-components:
#   - prometheus server
#   - alertmanager
#   - kube-state-metrics
#   - node-exporter
#   - pushgateway
# All referenced images will be automatically discovered and bundled.
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

OUTPUT_DIR="./bundles"
BUNDLE="${OUTPUT_DIR}/prometheus-28.13.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing Prometheus 3.10.0 (chart 28.13.0)..."
helm-airgap pack prometheus \
  --repo-url https://prometheus-community.github.io/helm-charts \
  --repo-name prometheus-community \
  --chart-version 28.13.0 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
