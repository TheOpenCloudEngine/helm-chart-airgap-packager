"""Extract Docker image references from rendered Helm templates and values files."""

import re
import tarfile
import os
import logging
from typing import Optional

import yaml

logger = logging.getLogger(__name__)

# Matches lines like: image: "nginx:1.21" or image: nginx:1.21 or image: repo/name:tag
_IMAGE_LINE_RE = re.compile(r'^\s*image:\s*["\']?([^\s"\'#]+)["\']?\s*(?:#.*)?$', re.MULTILINE)

# Matches OCI-style image refs: registry/repo/name:tag or registry/repo/name@sha256:...
_IMAGE_REF_RE = re.compile(
    r'(?P<registry>[a-zA-Z0-9._\-]+(?::[0-9]+)?/)?'
    r'(?P<repository>[a-zA-Z0-9._\-/]+)'
    r'(?::(?P<tag>[a-zA-Z0-9._\-]+))?'
    r'(?:@(?P<digest>sha256:[a-fA-F0-9]{64}))?'
)

# Well-known official image names (no slash) from Docker Hub
_OFFICIAL_IMAGES = {
    "nginx", "redis", "postgres", "mysql", "mongo", "alpine", "ubuntu",
    "debian", "python", "node", "golang", "java", "busybox", "scratch",
    "memcached", "rabbitmq", "kafka", "zookeeper", "elasticsearch",
    "kibana", "logstash", "grafana", "prometheus",
}


def normalize_image_ref(ref: str) -> str:
    """
    Normalize an image reference to fully-qualified form.

    Examples:
        nginx            -> docker.io/library/nginx:latest
        nginx:1.21       -> docker.io/library/nginx:1.21
        myrepo/app:v1    -> docker.io/myrepo/app:v1
        gcr.io/x/y:tag   -> gcr.io/x/y:tag
    """
    ref = ref.strip()
    if not ref or ref == "~" or len(ref) < 2:
        return ""

    # Already has a digest – keep as-is but ensure registry prefix
    has_digest = "@sha256:" in ref
    # Split off digest if present
    digest_part = ""
    if has_digest:
        ref, digest_part = ref.split("@", 1)
        digest_part = "@" + digest_part

    # Split tag
    tag = "latest"
    if ":" in ref.split("/")[-1]:
        ref, tag = ref.rsplit(":", 1)

    parts = ref.split("/")
    # Detect if first part is a registry (contains '.' or ':' or is 'localhost')
    if len(parts) >= 2 and ("." in parts[0] or ":" in parts[0] or parts[0] == "localhost"):
        registry = parts[0]
        repository = "/".join(parts[1:])
    else:
        registry = "docker.io"
        if len(parts) == 1:
            repository = f"library/{parts[0]}"
        else:
            repository = "/".join(parts)

    full = f"{registry}/{repository}:{tag}{digest_part}"
    return full


def _extract_images_from_yaml_text(text: str) -> set[str]:
    """Extract image references from a YAML/Helm-rendered text."""
    images: set[str] = set()
    for match in _IMAGE_LINE_RE.finditer(text):
        candidate = match.group(1).strip()
        # Skip obvious template variables
        if candidate.startswith("{{") or candidate == "null" or not candidate:
            continue
        normalized = normalize_image_ref(candidate)
        if normalized:
            images.add(normalized)
    return images


def extract_from_rendered_templates(rendered_yaml: str) -> set[str]:
    """
    Parse the output of `helm template` and collect all `image:` values.
    """
    return _extract_images_from_yaml_text(rendered_yaml)


def extract_from_values(values_data: dict, prefix: str = "") -> set[str]:
    """
    Recursively scan a values dict for common image patterns:
      - .image.repository + .image.tag
      - .image (plain string)
    """
    images: set[str] = set()

    if not isinstance(values_data, dict):
        return images

    # Pattern: {repository: ..., tag: ...}
    if "repository" in values_data:
        repo = values_data.get("repository", "")
        tag = values_data.get("tag", "latest") or "latest"
        registry = values_data.get("registry", "")
        if repo and isinstance(repo, str):
            if registry and isinstance(registry, str):
                ref = f"{registry}/{repo}:{tag}"
            else:
                ref = f"{repo}:{tag}"
            normalized = normalize_image_ref(ref)
            if normalized:
                images.add(normalized)

    # Pattern: {image: "full/ref:tag"}
    if "image" in values_data and isinstance(values_data["image"], str):
        normalized = normalize_image_ref(values_data["image"])
        if normalized:
            images.add(normalized)

    # Recurse into sub-dicts
    for key, value in values_data.items():
        if isinstance(value, dict):
            images |= extract_from_values(value, prefix=f"{prefix}.{key}")

    return images


def extract_from_values_file(values_path: str) -> set[str]:
    """Parse a values.yaml file and extract image references."""
    with open(values_path, "r") as f:
        data = yaml.safe_load(f) or {}
    return extract_from_values(data)


def extract_from_chart_tarball(chart_tgz: str, extra_values_files: Optional[list[str]] = None) -> set[str]:
    """
    Extract image references from a Helm chart .tgz by reading its values.yaml.
    This is a fallback for when `helm template` cannot be run.
    """
    images: set[str] = set()
    with tarfile.open(chart_tgz, "r:gz") as tar:
        for member in tar.getmembers():
            basename = os.path.basename(member.name)
            if basename == "values.yaml":
                f = tar.extractfile(member)
                if f:
                    content = f.read().decode("utf-8", errors="replace")
                    data = yaml.safe_load(content) or {}
                    images |= extract_from_values(data)

    for vf in (extra_values_files or []):
        images |= extract_from_values_file(vf)

    return images


def collect_images(
    rendered_yaml: Optional[str] = None,
    chart_tgz: Optional[str] = None,
    extra_values_files: Optional[list[str]] = None,
) -> list[str]:
    """
    Collect a deduplicated, sorted list of image references using all
    available sources (rendered templates preferred, values.yaml fallback).
    """
    images: set[str] = set()

    if rendered_yaml:
        found = extract_from_rendered_templates(rendered_yaml)
        logger.debug("Extracted %d images from rendered templates", len(found))
        images |= found

    if chart_tgz:
        found = extract_from_chart_tarball(chart_tgz, extra_values_files)
        logger.debug("Extracted %d images from chart values", len(found))
        images |= found

    # Filter out clearly invalid refs
    valid = sorted(img for img in images if img and "{{" not in img)
    return valid
