#!/usr/bin/env bash
# Load Harbor 2.14.2 airgap bundle images into minikube
# (Run install-harbor-minikube.sh to install after loading)
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

# ── Save chart to CHART_DIR ───────────────────────────────────────────────────
CHART_TGZ=$(find "$CHARTS_DIR" -name "*.tgz" | head -1)
if [ -z "$CHART_TGZ" ]; then
  echo "ERROR: No chart .tgz found in bundle"
  exit 1
fi

mkdir -p "$CHART_DIR"
cp "$CHART_TGZ" "$CHART_DIR/"

echo ""
echo "==> Chart saved to: $CHART_DIR/$(basename "$CHART_TGZ")"
echo ""
echo "Run ./install-harbor-minikube.sh to install."
