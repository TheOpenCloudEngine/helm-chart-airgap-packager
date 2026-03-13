#!/usr/bin/env bash
# Example: Pack NGINX Ingress Controller 1.15.0 (ingress-nginx/ingress-nginx chart 4.15.0) for airgap deployment
#
# Source command:
#   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#   helm pull ingress-nginx/ingress-nginx --version 4.15.0
#
# Note: The Ingress NGINX Controller is the most widely used Kubernetes ingress controller.
#       It uses the official ingress-nginx controller image from registry.k8s.io.
#
# Prerequisites:
#   - helm CLI installed
#   - docker or podman installed and running

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/ingress-nginx-4.15.0-airgap.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "==> If image pull fails, run manually:"
echo "  docker pull registry.k8s.io/ingress-nginx/controller:v1.15.0"
echo "  docker pull registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.3"
echo ""
echo "==> Packing NGINX Ingress Controller 1.15.0 (chart 4.15.0)..."
helm-airgap pack ingress-nginx \
  --repo-url https://kubernetes.github.io/ingress-nginx \
  --repo-name opencloudengine \
  --chart-version 4.15.0 \
  --chart-dir "$CHART_DIR" \
  --images-dir "$IMAGES_DIR/ingress-nginx-4.15.0" \
  --include-image registry.k8s.io/ingress-nginx/controller:v1.15.0 \
  --include-image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.3 \
  -o "$BUNDLE" \
  -v

echo ""
echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "Bundle created: $BUNDLE"
