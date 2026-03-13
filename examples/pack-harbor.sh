#!/usr/bin/env bash
# Example: Pack Harbor 2.14.2 (harbor/harbor chart 1.18.2) for airgap deployment
#
# Source command:
#   helm repo add harbor https://helm.goharbor.io
#   helm pull harbor/harbor --version 1.18.2
#
# Note: Harbor is an open source cloud native registry that stores, signs, and scans
#       container images and other artifacts. It includes multiple components:
#         - nginx-photon         : reverse proxy / portal entrypoint
#         - harbor-portal        : web UI (nginx-based frontend)
#         - harbor-core          : core service (API, auth, replication)
#         - harbor-jobservice    : async job service
#         - registry-photon      : OCI distribution registry
#         - harbor-registryctl   : registry controller sidecar
#         - trivy-adapter-photon : vulnerability scanner adapter
#         - harbor-db            : embedded PostgreSQL
#         - redis-photon         : embedded Redis
#         - harbor-exporter      : Prometheus metrics exporter
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/harbor-1.18.2-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull goharbor/nginx-photon:v2.14.2"
echo "  docker pull goharbor/harbor-portal:v2.14.2"
echo "  docker pull goharbor/harbor-core:v2.14.2"
echo "  docker pull goharbor/harbor-jobservice:v2.14.2"
echo "  docker pull goharbor/registry-photon:v2.14.2"
echo "  docker pull goharbor/harbor-registryctl:v2.14.2"
echo "  docker pull goharbor/trivy-adapter-photon:v2.14.2"
echo "  docker pull goharbor/harbor-db:v2.14.2"
echo "  docker pull goharbor/redis-photon:v2.14.2"
echo "  docker pull goharbor/harbor-exporter:v2.14.2"
echo ""
echo "==> Packing Harbor 2.14.2 (chart 1.18.2)..."
helm-airgap pack harbor \
  --repo-url https://helm.goharbor.io \
  --repo-name opencloudengine \
  --chart-version 1.18.2 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/harbor-1.18.2" \
  --include-image goharbor/nginx-photon:v2.14.2 \
  --include-image goharbor/harbor-portal:v2.14.2 \
  --include-image goharbor/harbor-core:v2.14.2 \
  --include-image goharbor/harbor-jobservice:v2.14.2 \
  --include-image goharbor/registry-photon:v2.14.2 \
  --include-image goharbor/harbor-registryctl:v2.14.2 \
  --include-image goharbor/trivy-adapter-photon:v2.14.2 \
  --include-image goharbor/harbor-db:v2.14.2 \
  --include-image goharbor/redis-photon:v2.14.2 \
  --include-image goharbor/harbor-exporter:v2.14.2 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
