"""Docker / container image utilities: pull, save, load, push, retag."""

import subprocess
import os
import shutil
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def _run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    logger.debug("Running: %s", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}"
        )
    return result


def check_docker() -> None:
    """Verify that a container runtime (docker or podman) is available."""
    for runtime in ("docker", "podman"):
        if shutil.which(runtime):
            return
    raise EnvironmentError(
        "Neither 'docker' nor 'podman' found. Please install one of them."
    )


def _runtime() -> str:
    """Return the available container runtime binary name."""
    for runtime in ("docker", "podman"):
        if shutil.which(runtime):
            return runtime
    raise EnvironmentError("No container runtime found (docker/podman).")


def image_filename(image_ref: str) -> str:
    """
    Convert an image reference to a safe filename.

    docker.io/library/nginx:1.21  ->  docker.io_library_nginx_1.21.tar
    """
    safe = image_ref.replace("/", "_").replace(":", "_").replace("@", "_")
    return safe + ".tar"


def pull_image(image_ref: str) -> None:
    """Pull an image from a registry."""
    logger.info("Pulling image: %s", image_ref)
    _run([_runtime(), "pull", image_ref])


def save_image(image_ref: str, dest_path: str) -> None:
    """Save an image to a tar file."""
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    logger.info("Saving image %s -> %s", image_ref, dest_path)
    _run([_runtime(), "save", "-o", dest_path, image_ref])


def pull_and_save(image_ref: str, dest_dir: str) -> str:
    """Pull an image and save it as a tar file. Returns the tar path."""
    pull_image(image_ref)
    filename = image_filename(image_ref)
    dest_path = os.path.join(dest_dir, filename)
    save_image(image_ref, dest_path)
    return dest_path


def load_image(tar_path: str) -> None:
    """Load an image from a tar file into the local container runtime."""
    logger.info("Loading image from: %s", tar_path)
    _run([_runtime(), "load", "-i", tar_path])


def push_image(image_ref: str, registry: Optional[str] = None, insecure: bool = False) -> str:
    """
    Push an image to a registry.

    If registry is given, the image is retagged to target_registry/repo:tag
    and then pushed. Returns the final pushed reference.
    """
    if registry:
        target_ref = retag_for_registry(image_ref, registry)
    else:
        target_ref = image_ref

    cmd = [_runtime(), "push", target_ref]
    if insecure and _runtime() == "docker":
        # docker doesn't support --tls-verify but we can note it
        pass
    elif insecure and _runtime() == "podman":
        cmd += ["--tls-verify=false"]

    logger.info("Pushing image: %s", target_ref)
    _run(cmd)
    return target_ref


def retag_for_registry(image_ref: str, target_registry: str) -> str:
    """
    Retag an image to point at target_registry.

    docker.io/library/nginx:1.21, myregistry.local:5000
      -> myregistry.local:5000/library/nginx:1.21
    """
    target_registry = target_registry.rstrip("/")
    # Strip the existing registry prefix (everything before first slash-less part)
    parts = image_ref.split("/")
    # parts[0] is the registry if it contains '.' or ':'
    if len(parts) >= 2 and ("." in parts[0] or ":" in parts[0] or parts[0] == "localhost"):
        repo_and_tag = "/".join(parts[1:])
    else:
        repo_and_tag = "/".join(parts)

    new_ref = f"{target_registry}/{repo_and_tag}"
    logger.info("Retagging %s -> %s", image_ref, new_ref)
    _run([_runtime(), "tag", image_ref, new_ref])
    return new_ref


def load_and_push(tar_path: str, target_registry: str, insecure: bool = False) -> list[str]:
    """
    Load a tar file and push all contained images to target_registry.
    Returns a list of pushed image references.
    """
    # Load the tar – docker/podman prints the loaded tags
    result = _run([_runtime(), "load", "-i", tar_path])
    pushed: list[str] = []

    for line in result.stdout.splitlines():
        # "Loaded image: <ref>" or "Loaded image ID: sha256:..."
        if "Loaded image:" in line and "ID:" not in line:
            loaded_ref = line.split("Loaded image:")[-1].strip()
            pushed_ref = push_image(loaded_ref, registry=target_registry, insecure=insecure)
            pushed.append(pushed_ref)

    return pushed
