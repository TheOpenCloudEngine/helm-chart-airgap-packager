#!/usr/bin/env bash
# Load MariaDB Operator 25.10.4 airgap bundle images into minikube
# (Run install-mariadb-minikube.sh to install after loading)
#
# Usage:
#   ./load-mariadb-minikube.sh
#
# Prerequisites:
#   - minikube running (minikube start)
#   - helm CLI installed
#   - Bundle created by pack-mariadb.sh
#
# Note: This installs the mariadb-operator.
#       After installation, create a MariaDB instance with a MariaDB CRD, e.g.:
#         kubectl apply -f - <<EOF
#         apiVersion: k8s.mariadb.com/v1alpha1
#         kind: MariaDB
#         metadata:
#           name: my-mariadb
#         spec:
#           rootPasswordSecretKeyRef:
#             name: mariadb-secret
#             key: password
#           image: mariadb:11.4
#           storage:
#             size: 1Gi
#         EOF

set -euo pipefail

. "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/mariadb-operator-25.10.4-airgap.tar.gz"

# ── Preflight ─────────────────────────────────────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  echo "ERROR: minikube is not running. Start it with: minikube start"
  exit 1
fi

if [ ! -f "$BUNDLE" ]; then
  echo "ERROR: Bundle not found: $BUNDLE"
  echo "       Run pack-mariadb.sh first."
  exit 1
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
echo "==> Loading images into minikube..."
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
echo "Run ./install-mariadb-minikube.sh to install."
