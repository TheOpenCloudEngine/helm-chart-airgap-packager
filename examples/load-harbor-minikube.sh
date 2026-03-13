#!/usr/bin/env bash
# Load Harbor 2.14.2 airgap bundle images into minikube and install
#
# Usage:
#   ./load-harbor-minikube.sh
#
# Prerequisites:
#   - minikube running with ingress addon enabled:
#       minikube start --memory=4096 --cpus=2
#       minikube addons enable ingress
#   - helm CLI installed
#   - Bundle created by pack-harbor.sh
#
# After installation, Harbor UI is accessible at:
#   http://harbor.local  (add to /etc/hosts: $(minikube ip) harbor.local)

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/harbor-1.18.2-airgap.tar.gz"
RELEASE="harbor"
NAMESPACE="shared-apps"
HARBOR_HOSTNAME="harbor.local"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running."
  echo "       Start with: minikube start --memory=4096 --cpus=2"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-harbor.sh first."
  exit 1
fi

# ── Check ingress addon ────────────────────────────────────────────────────────
if ! minikube addons list | grep -E "^ingress\s+\|.*enabled" &>/dev/null; then
  echo "WARNING: minikube ingress addon is not enabled."
  echo "         Enabling it now..."
  minikube addons enable ingress
fi

# ── Extract bundle ─────────────────────────────────────────────────────────────
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

echo "==> Extracting bundle: $BUNDLE"
tar xzf "$BUNDLE" -C "$TMPDIR_WORK"

BUNDLE_DIR=$(find "$TMPDIR_WORK" -mindepth 1 -maxdepth 1 -type d | head -1)
IMAGES_DIR="$BUNDLE_DIR/images"
CHARTS_DIR="$BUNDLE_DIR/charts"

# ── Load images into minikube ─────────────────────────────────────────────────
echo ""
echo "==> Loading images into minikube (10 components)..."
for img_tar in "$IMAGES_DIR"/*.tar; do
  [ -f "$img_tar" ] || continue
  echo "    $(basename "$img_tar")"
  minikube image load "$img_tar"
done
echo "    Images loaded."

# ── Locate chart ──────────────────────────────────────────────────────────────
CHART_TGZ=$(find "$CHARTS_DIR" -name "*.tgz" | head -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No chart .tgz found in bundle"
  exit 1
fi

# ── Helm install ──────────────────────────────────────────────────────────────
MINIKUBE_IP=$(minikube ip)

echo ""
echo "==> Installing Harbor (release: $RELEASE, namespace: $NAMESPACE)..."
echo "    Hostname : $HARBOR_HOSTNAME (minikube IP: $MINIKUBE_IP)"
helm upgrade --install "$RELEASE" "$CHART_TGZ" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "expose.type=ingress" \
  --set "expose.ingress.hosts.core=${HARBOR_HOSTNAME}" \
  --set "expose.ingress.hosts.notary=notary.${HARBOR_HOSTNAME}" \
  --set "externalURL=http://${HARBOR_HOSTNAME}" \
  --set "expose.tls.enabled=false" \
  --set "harborAdminPassword=Harbor12345" \
  --set "nginx.image.pullPolicy=IfNotPresent" \
  --set "portal.image.pullPolicy=IfNotPresent" \
  --set "core.image.pullPolicy=IfNotPresent" \
  --set "jobservice.image.pullPolicy=IfNotPresent" \
  --set "registry.registry.image.pullPolicy=IfNotPresent" \
  --set "registry.controller.image.pullPolicy=IfNotPresent" \
  --set "trivy.image.pullPolicy=IfNotPresent" \
  --set "database.internal.image.pullPolicy=IfNotPresent" \
  --set "redis.internal.image.pullPolicy=IfNotPresent" \
  --set "exporter.image.pullPolicy=IfNotPresent" \
  --set "persistence.persistentVolumeClaim.registry.size=5Gi" \
  --set "persistence.persistentVolumeClaim.jobservice.jobLog.size=1Gi" \
  --set "persistence.persistentVolumeClaim.database.size=1Gi" \
  --set "persistence.persistentVolumeClaim.redis.size=1Gi" \
  --set "persistence.persistentVolumeClaim.trivy.size=2Gi" \
  --timeout 10m \
  --wait

echo ""
echo "Done! Harbor release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "==> Add the following entry to /etc/hosts:"
echo "    ${MINIKUBE_IP}  ${HARBOR_HOSTNAME}"
echo ""
echo "    Or run: echo \"${MINIKUBE_IP}  ${HARBOR_HOSTNAME}\" | sudo tee -a /etc/hosts"
echo ""
echo "Access Harbor UI:"
echo "  http://${HARBOR_HOSTNAME}  (admin / Harbor12345)"
echo ""
echo "Login via Docker CLI:"
echo "  docker login ${HARBOR_HOSTNAME} -u admin -p Harbor12345"

# ── Pod status ────────────────────────────────────────────────────────────────
echo ""
echo "==> Pod status in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE"
