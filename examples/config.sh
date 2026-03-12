#!/usr/bin/env bash
# Common configuration for helm-airgap example scripts.
# Edit these values to match your environment before running pack-*.sh / install-*.sh.

# ── Registry ──────────────────────────────────────────────────────────────────
# Private container registry in the airgap environment.
REGISTRY="myregistry.local:5000"

# ── Namespace ─────────────────────────────────────────────────────────────────
# Default Kubernetes namespace. Each install-*.sh overrides this with a
# chart-specific value after sourcing this file.
NAMESPACE="default"

# ── Directories ───────────────────────────────────────────────────────────────
# Directory where downloaded Helm chart .tgz files are saved.
CHART_DIR="./charts"

# Directory where docker save image .tar files are saved.
IMAGES_DIR="./images"

# Directory where airgap bundle .tar.gz files are saved.
OUTPUT_DIR="./bundles"
