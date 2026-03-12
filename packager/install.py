"""
Install command: extract an airgap bundle, load images, and install the Helm chart.

Workflow:
  1. Extract the bundle .tar.gz
  2. (Optional) Push images to a private registry
  3. Load images into local Docker/Podman (if no registry)
  4. Run `helm upgrade --install` with optional image override values
"""

import json
import logging
import os
import tarfile
import tempfile
from typing import Optional

from . import helm_utils, docker_utils

logger = logging.getLogger(__name__)


def install(
    bundle_path: str,
    release_name: str,
    namespace: str = "default",
    registry: Optional[str] = None,
    registry_insecure: bool = False,
    values_files: Optional[list[str]] = None,
    set_values: Optional[list[str]] = None,
    skip_load: bool = False,
    skip_push: bool = False,
    skip_helm: bool = False,
    create_namespace: bool = True,
    wait: bool = False,
) -> None:
    """
    Install a Helm chart from an airgap bundle.

    Parameters
    ----------
    bundle_path      : Path to the .tar.gz bundle created by `pack`
    release_name     : Helm release name
    namespace        : Kubernetes namespace
    registry         : Target private registry (e.g. myregistry.local:5000).
                       When given, images are pushed there and Helm values are
                       overridden to use the new registry.
    registry_insecure: Allow insecure (HTTP) registry
    values_files     : Additional Helm values files
    set_values       : Additional --set overrides
    skip_load        : Skip loading images into local runtime
    skip_push        : Skip pushing images to registry (even if registry is set)
    skip_helm        : Only handle images, skip Helm install
    create_namespace : Pass --create-namespace to Helm
    wait             : Pass --wait to Helm
    """
    helm_utils.check_helm()
    if not skip_load and not skip_push:
        docker_utils.check_docker()

    with tempfile.TemporaryDirectory(prefix="airgap-install-") as tmpdir:
        # ── 1. Extract bundle ────────────────────────────────────────────────
        logger.info("Extracting bundle: %s", bundle_path)
        with tarfile.open(bundle_path, "r:gz") as tar:
            tar.extractall(tmpdir)

        # Find the top-level bundle directory
        entries = os.listdir(tmpdir)
        if len(entries) != 1 or not os.path.isdir(os.path.join(tmpdir, entries[0])):
            raise RuntimeError(
                f"Unexpected bundle structure. Expected a single top-level directory, got: {entries}"
            )
        bundle_dir = os.path.join(tmpdir, entries[0])
        manifest_path = os.path.join(bundle_dir, "manifest.json")
        charts_dir = os.path.join(bundle_dir, "charts")
        images_dir = os.path.join(bundle_dir, "images")

        # ── 2. Read manifest ─────────────────────────────────────────────────
        with open(manifest_path) as f:
            manifest = json.load(f)

        chart_info = manifest.get("chart", {})
        chart_filename = chart_info.get("filename")
        if not chart_filename:
            raise RuntimeError("manifest.json is missing 'chart.filename'")

        chart_tgz = os.path.join(charts_dir, chart_filename)
        if not os.path.isfile(chart_tgz):
            raise FileNotFoundError(f"Chart tarball not found in bundle: {chart_tgz}")

        images_manifest: list[dict] = manifest.get("images", [])
        logger.info(
            "Bundle: chart=%s version=%s, images=%d",
            chart_info.get("name"), chart_info.get("version"), len(images_manifest),
        )

        # ── 3. Load / push images ────────────────────────────────────────────
        pushed_refs: dict[str, str] = {}  # original_ref -> pushed_ref

        if os.path.isdir(images_dir) and not skip_load:
            for img_entry in images_manifest:
                if img_entry.get("status") == "failed":
                    logger.warning("Skipping previously-failed image: %s", img_entry["ref"])
                    continue

                tar_path = os.path.join(images_dir, img_entry["filename"])
                if not os.path.isfile(tar_path):
                    logger.warning("Image tar not found (skipping): %s", tar_path)
                    continue

                if registry and not skip_push:
                    pushed = docker_utils.load_and_push(tar_path, registry, insecure=registry_insecure)
                    for ref in pushed:
                        pushed_refs[img_entry["ref"]] = ref
                else:
                    docker_utils.load_image(tar_path)
        else:
            logger.info("Skipping image load (no images directory or --skip-load set)")

        # ── 4. Build Helm override values for registry ───────────────────────
        auto_set: list[str] = []
        if registry and pushed_refs:
            # Attempt to set global registry override (works for many charts)
            auto_set.append(f"global.imageRegistry={registry}")
            logger.info("Setting global.imageRegistry=%s", registry)

        combined_set = (set_values or []) + auto_set

        # ── 5. Helm install ──────────────────────────────────────────────────
        if not skip_helm:
            logger.info("Installing chart as release '%s' in namespace '%s'", release_name, namespace)
            helm_utils.install_chart(
                release_name=release_name,
                chart_path=chart_tgz,
                namespace=namespace,
                values_files=values_files,
                set_values=combined_set if combined_set else None,
                create_namespace=create_namespace,
                wait=wait,
            )
            logger.info("Installation complete.")
        else:
            logger.info("Skipping Helm install (--skip-helm set)")


def list_bundle_contents(bundle_path: str) -> dict:
    """
    Parse a bundle and return its manifest without extracting images.
    Useful for inspecting what a bundle contains before installing.
    """
    with tarfile.open(bundle_path, "r:gz") as tar:
        manifest_members = [m for m in tar.getmembers() if m.name.endswith("manifest.json")]
        if not manifest_members:
            raise RuntimeError("No manifest.json found in bundle")
        f = tar.extractfile(manifest_members[0])
        if not f:
            raise RuntimeError("Could not read manifest.json from bundle")
        return json.load(f)
