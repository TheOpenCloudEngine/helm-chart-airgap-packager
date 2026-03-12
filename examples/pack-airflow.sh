#!/usr/bin/env bash
# Example: Pack Apache Airflow 3.1.7 (Helm chart 1.19.0) for airgap deployment
#
# Source command:
#   helm repo add apache-airflow https://airflow.apache.org/
#   helm pull apache-airflow/airflow --version 1.19.0
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/airflow-1.19.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> Packing Apache Airflow 3.1.7 (chart 1.19.0)..."
helm-airgap pack airflow \
  --repo-url https://airflow.apache.org/ \
  --repo-name apache-airflow \
  --chart-version 1.19.0 \
  --chart-dir "$CHART_DIR" \
  --include-image apache/airflow:3.1.7 \
  --include-image bitnami/postgresql:16.4.0 \
  --include-image bitnami/redis:7.4.2 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
