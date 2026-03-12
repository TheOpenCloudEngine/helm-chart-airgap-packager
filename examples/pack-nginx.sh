#!/usr/bin/env bash
# Example: Pack bitnami/nginx chart from the official Bitnami repo

source "$(dirname "$0")/config.sh"

helm-airgap pack nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --repo-name bitnami \
  --chart-version 15.14.0 \
  --chart-dir "$CHART_DIR" \
  --include-image bitnami/nginx:1.25.3 \
  -o ./bundles/nginx-15.14.0-airgap.tar.gz \
  -v

echo "Bundle created at ./bundles/nginx-15.14.0-airgap.tar.gz"
