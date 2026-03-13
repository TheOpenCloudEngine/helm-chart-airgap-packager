#!/usr/bin/env bash
# Example: Pack Apache Airflow 3.1.7 (Helm chart 1.19.0) for airgap deployment
#
# Source command:
#   helm repo add apache-airflow https://airflow.apache.org/
#   helm pull apache-airflow/airflow --version 1.19.0
#
# Note: The official Apache Airflow chart uses PostgreSQL and Redis as subcharts.
#       Override subchart images to use official Docker Hub images instead of defaults:
#         postgresql.image.repository=postgres, postgresql.image.tag=17
#         redis.image.repository=redis, redis.image.tag=7
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/airflow-1.19.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull apache/airflow:3.1.7"
echo "  docker pull postgres:17"
echo "  docker pull redis:7"
echo ""
echo "==> Packing Apache Airflow 3.1.7 (chart 1.19.0)..."
helm-airgap pack airflow \
  --repo-url https://airflow.apache.org/ \
  --repo-name apache-airflow \
  --chart-version 1.19.0 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/airflow-1.19.0" \
  --include-image apache/airflow:3.1.7 \
  --include-image postgres:17 \
  --include-image redis:7 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
