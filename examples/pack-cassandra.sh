#!/usr/bin/env bash
# Example: Pack Apache Cassandra 5.0 via K8ssandra Operator 1.29.0 (k8ssandra/k8ssandra-operator chart 1.29.0) for airgap deployment
#
# Source command:
#   helm repo add k8ssandra https://helm.k8ssandra.io/stable
#   helm pull k8ssandra/k8ssandra-operator --version 1.29.0
#
# Note: K8ssandra Operator is the most widely used Kubernetes operator for Apache Cassandra.
#       It manages Cassandra clusters using the cass-management-api sidecar image.
#       The cass-management-api image wraps the Apache Cassandra server with a management REST API.
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/k8ssandra-1.29.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull docker.io/k8ssandra/k8ssandra-operator:v1.29.0"
echo "  docker pull docker.io/k8ssandra/cass-management-api:5.0.2-ubi"
echo "  docker pull docker.io/k8ssandra/system-logger:v1.29.0"
echo ""
echo "==> Packing K8ssandra Operator 1.29.0 with Cassandra 5.0 (chart 1.29.0)..."
helm-airgap pack k8ssandra-operator \
  --repo-url https://helm.k8ssandra.io/stable \
  --repo-name opencloudengine \
  --chart-version 1.29.0 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/k8ssandra-1.29.0" \
  --include-image docker.io/k8ssandra/k8ssandra-operator:v1.29.0 \
  --include-image docker.io/k8ssandra/cass-management-api:5.0.2-ubi \
  --include-image docker.io/k8ssandra/system-logger:v1.29.0 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
