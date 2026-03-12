"""
Pack command: bundle a Helm chart + all referenced Docker images
into a single .tar.gz archive for airgap deployment.

Bundle layout:
  <bundle>.tar.gz
  └── <chart-name>-<version>/
      ├── manifest.json        # metadata: chart info, image list, tool versions
      ├── charts/
      │   └── <chart>.tgz      # Helm chart tarball
      └── images/
          ├── <image1>.tar     # Docker image save files
          └── <image2>.tar
"""

import json
import logging
import os
import shutil
import tarfile
import tempfile
from datetime import datetime, timezone
from typing import Optional

from . import __version__
from . import helm_utils, docker_utils, image_extractor

logger = logging.getLogger(__name__)


def pack(
    chart: str,
    output: str,
    chart_version: Optional[str] = None,
    repo_url: Optional[str] = None,
    repo_name: Optional[str] = None,
    repo_username: Optional[str] = None,
    repo_password: Optional[str] = None,
    values_files: Optional[list[str]] = None,
    set_values: Optional[list[str]] = None,
    skip_images: bool = False,
    include_images: Optional[list[str]] = None,
    exclude_images: Optional[list[str]] = None,
    platforms: Optional[list[str]] = None,
) -> str:
    """
    Create an airgap bundle.

    Parameters
    ----------
    chart         : Chart name (repo/chart), OCI ref, or path to local chart/.tgz
    output        : Output .tar.gz path (or directory – filename will be auto-generated)
    chart_version : Helm chart version to pull (optional)
    repo_url      : Helm repo URL (used with repo_name for `helm repo add`)
    repo_name     : Alias for the Helm repo
    values_files  : List of extra values files for image extraction / helm template
    set_values    : List of --set overrides for helm template
    skip_images   : When True, only bundle the chart without images
    include_images: Explicit list of images to add (in addition to discovered ones)
    exclude_images: List of image refs to skip (substring match)
    platforms     : (future) List of platforms for multi-arch pulls

    Returns
    -------
    Path to the created bundle .tar.gz file.
    """
    helm_utils.check_helm()
    if not skip_images:
        docker_utils.check_docker()

    with tempfile.TemporaryDirectory(prefix="airgap-pack-") as tmpdir:
        charts_dir = os.path.join(tmpdir, "charts")
        images_dir = os.path.join(tmpdir, "images")
        os.makedirs(charts_dir)
        os.makedirs(images_dir)

        # ── 1. Fetch the Helm chart ──────────────────────────────────────────
        logger.info("Fetching chart: %s", chart)
        is_local = os.path.exists(chart)

        if is_local:
            if chart.endswith(".tgz") or chart.endswith(".tar.gz"):
                chart_tgz = chart
                chart_name = os.path.basename(chart).replace(".tgz", "").replace(".tar.gz", "")
            else:
                # Local directory – package it first
                result = _run_helm_package(chart, charts_dir)
                chart_tgz = result
                chart_name = os.path.basename(result).rsplit("-", 1)[0]
        else:
            if repo_url and repo_name:
                helm_utils.repo_add(
                    repo_name, repo_url,
                    username=repo_username, password=repo_password,
                )
            chart_tgz = helm_utils.pull_chart(
                chart, charts_dir,
                version=chart_version,
                repo_url=repo_url if not repo_name else None,
                username=repo_username,
                password=repo_password,
            )
            chart_name = os.path.basename(chart_tgz).rsplit("-", 1)[0]

        # Copy chart tgz into the bundle's charts/ dir
        chart_tgz_in_bundle = os.path.join(charts_dir, os.path.basename(chart_tgz))
        if os.path.abspath(chart_tgz) != os.path.abspath(chart_tgz_in_bundle):
            shutil.copy2(chart_tgz, chart_tgz_in_bundle)

        # ── 2. Discover images ───────────────────────────────────────────────
        images: list[str] = []
        if not skip_images:
            rendered_yaml: Optional[str] = None
            try:
                rendered_yaml = helm_utils.render_templates(
                    chart_tgz_in_bundle,
                    values_files=values_files,
                    set_values=set_values,
                )
            except RuntimeError as e:
                logger.warning("helm template failed, falling back to values.yaml parsing: %s", e)

            images = image_extractor.collect_images(
                rendered_yaml=rendered_yaml,
                chart_tgz=chart_tgz_in_bundle,
                extra_values_files=values_files,
            )

            # Apply include list
            if include_images:
                for img in include_images:
                    norm = image_extractor.normalize_image_ref(img)
                    if norm and norm not in images:
                        images.append(norm)

            # Apply exclude filter
            if exclude_images:
                images = [
                    img for img in images
                    if not any(excl in img for excl in exclude_images)
                ]

            logger.info("Discovered %d image(s):", len(images))
            for img in images:
                logger.info("  %s", img)

        # ── 3. Pull & save images ────────────────────────────────────────────
        failed_images: list[str] = []
        if not skip_images:
            for img in images:
                try:
                    docker_utils.pull_and_save(img, images_dir)
                except RuntimeError as e:
                    logger.error("Failed to pull/save image %s: %s", img, e)
                    failed_images.append(img)

        # ── 4. Write manifest ────────────────────────────────────────────────
        chart_basename = os.path.basename(chart_tgz_in_bundle)
        # Parse version from filename: name-version.tgz
        parts = chart_basename.replace(".tgz", "").rsplit("-", 1)
        chart_ver = parts[1] if len(parts) == 2 else "unknown"

        manifest = {
            "apiVersion": "airgap.helm/v1",
            "packager_version": __version__,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "chart": {
                "name": chart_name,
                "version": chart_ver,
                "filename": chart_basename,
            },
            "images": [
                {
                    "ref": img,
                    "filename": docker_utils.image_filename(img),
                    "status": "failed" if img in failed_images else "ok",
                }
                for img in images
            ],
            "failed_images": failed_images,
        }

        manifest_path = os.path.join(tmpdir, "manifest.json")
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)

        if failed_images:
            logger.warning("%d image(s) failed to pull:", len(failed_images))
            for img in failed_images:
                logger.warning("  %s", img)

        # ── 5. Create the output archive ─────────────────────────────────────
        bundle_dirname = f"{chart_name}-{chart_ver}"

        if output.endswith("/") or os.path.isdir(output):
            os.makedirs(output, exist_ok=True)
            output = os.path.join(output, f"{bundle_dirname}-airgap.tar.gz")

        output = os.path.abspath(output)
        os.makedirs(os.path.dirname(output), exist_ok=True)

        logger.info("Creating bundle archive: %s", output)
        with tarfile.open(output, "w:gz") as tar:
            tar.add(manifest_path, arcname=f"{bundle_dirname}/manifest.json")
            tar.add(charts_dir, arcname=f"{bundle_dirname}/charts")
            if not skip_images:
                tar.add(images_dir, arcname=f"{bundle_dirname}/images")

        size_mb = os.path.getsize(output) / (1024 * 1024)
        logger.info("Bundle created: %s (%.1f MB)", output, size_mb)
        return output


def _run_helm_package(chart_dir: str, dest: str) -> str:
    """Run `helm package` on a local chart directory."""
    import subprocess
    result = subprocess.run(
        ["helm", "package", chart_dir, "--destination", dest],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"helm package failed:\n{result.stderr}")
    tarballs = [f for f in os.listdir(dest) if f.endswith(".tgz")]
    if not tarballs:
        raise FileNotFoundError("helm package produced no .tgz file")
    tarballs.sort(key=lambda f: os.path.getmtime(os.path.join(dest, f)), reverse=True)
    return os.path.join(dest, tarballs[0])
