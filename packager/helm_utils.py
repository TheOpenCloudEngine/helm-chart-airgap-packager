"""Helm CLI wrapper utilities."""

import subprocess
import os
import shutil
import tempfile
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def _run(cmd: list[str], cwd: Optional[str] = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    logger.debug("Running: %s", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    if check and result.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}"
        )
    return result


def check_helm() -> None:
    """Verify that the helm binary is available."""
    if not shutil.which("helm"):
        raise EnvironmentError("'helm' binary not found. Please install Helm: https://helm.sh/docs/intro/install/")


def repo_add(name: str, url: str, username: Optional[str] = None, password: Optional[str] = None) -> None:
    """Add a Helm chart repository."""
    cmd = ["helm", "repo", "add", name, url]
    if username:
        cmd += ["--username", username]
    if password:
        cmd += ["--password", password]
    _run(cmd)
    _run(["helm", "repo", "update", name])
    logger.info("Added and updated Helm repo '%s' -> %s", name, url)


def pull_chart(
    chart: str,
    dest_dir: str,
    version: Optional[str] = None,
    repo_url: Optional[str] = None,
    username: Optional[str] = None,
    password: Optional[str] = None,
) -> str:
    """
    Pull a Helm chart tarball into dest_dir.

    chart: 'repo/name' or just 'name' when repo_url is given
    Returns the path to the downloaded .tgz file.
    """
    os.makedirs(dest_dir, exist_ok=True)
    cmd = ["helm", "pull", chart, "--destination", dest_dir]
    if version:
        cmd += ["--version", version]
    if repo_url:
        cmd += ["--repo", repo_url]
    if username:
        cmd += ["--username", username]
    if password:
        cmd += ["--password", password]
    _run(cmd)

    tarballs = [f for f in os.listdir(dest_dir) if f.endswith(".tgz")]
    if not tarballs:
        raise FileNotFoundError(f"No .tgz chart found in {dest_dir} after helm pull")
    # Return the most recently created one
    tarballs.sort(key=lambda f: os.path.getmtime(os.path.join(dest_dir, f)), reverse=True)
    return os.path.join(dest_dir, tarballs[0])


def render_templates(chart_path: str, values_files: Optional[list[str]] = None, set_values: Optional[list[str]] = None) -> str:
    """
    Run `helm template` on a chart and return the rendered YAML string.

    chart_path: path to a local chart directory or .tgz archive
    """
    cmd = ["helm", "template", "release", chart_path, "--include-crds"]
    for vf in (values_files or []):
        cmd += ["-f", vf]
    for sv in (set_values or []):
        cmd += ["--set", sv]

    result = _run(cmd)
    return result.stdout


def install_chart(
    release_name: str,
    chart_path: str,
    namespace: str = "default",
    values_files: Optional[list[str]] = None,
    set_values: Optional[list[str]] = None,
    create_namespace: bool = True,
    wait: bool = False,
) -> None:
    """Install or upgrade a Helm chart."""
    cmd = [
        "helm", "upgrade", "--install", release_name, chart_path,
        "--namespace", namespace,
    ]
    if create_namespace:
        cmd.append("--create-namespace")
    if wait:
        cmd.append("--wait")
    for vf in (values_files or []):
        cmd += ["-f", vf]
    for sv in (set_values or []):
        cmd += ["--set", sv]

    _run(cmd)
    logger.info("Helm chart '%s' installed/upgraded as release '%s' in namespace '%s'", chart_path, release_name, namespace)
