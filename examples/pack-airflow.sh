#!/usr/bin/env bash
# Example: Pack Apache Airflow 3.1.7 (Helm chart 1.19.0) for airgap deployment
#
# Source command:
#   helm repo add apache-airflow https://airflow.apache.org/
#   helm pull apache-airflow/airflow --version 1.19.0
#
# Note: The official Apache Airflow chart uses PostgreSQL as a subchart.
#       Its default values reference old bitnami/debian-11 images that are no longer
#       available on Docker Hub. We exclude bitnami images and use the official
#       postgres image instead: postgresql.image.repository=postgres, tag=17
#       Redis image override is not supported by the chart schema; the chart uses
#       its own built-in redis image.
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
  --exclude-image bitnami \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
