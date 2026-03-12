"""CLI entry point for helm-airgap-packager."""

import json
import logging
import sys

import click

from . import __version__
from . import pack as pack_module
from . import install as install_module


def _setup_logging(verbose: bool) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
        level=level,
        stream=sys.stderr,
    )


# ── Root group ──────────────────────────────────────────────────────────────

@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.version_option(__version__, "-V", "--version")
@click.pass_context
def cli(ctx: click.Context) -> None:
    """
    helm-airgap-packager – Bundle Helm charts and Docker images for airgap deployment.

    \b
    Typical workflow:
      # On an internet-connected machine:
      helm-airgap pack bitnami/nginx --repo-url https://charts.bitnami.com/bitnami -o nginx-bundle.tar.gz

      # Transfer nginx-bundle.tar.gz to the airgap machine, then:
      helm-airgap install nginx-bundle.tar.gz my-nginx --registry myregistry.local:5000
    """
    ctx.ensure_object(dict)


# ── pack command ─────────────────────────────────────────────────────────────

@cli.command("pack")
@click.argument("chart")
@click.option("-o", "--output", required=True, metavar="PATH",
              help="Output bundle path (.tar.gz) or directory.")
@click.option("--chart-version", metavar="VERSION",
              help="Helm chart version to pull (default: latest).")
@click.option("--repo-url", metavar="URL",
              help="Helm repository URL (e.g. https://charts.bitnami.com/bitnami).")
@click.option("--repo-name", metavar="NAME", default="airgap-repo", show_default=True,
              help="Local alias for the Helm repository.")
@click.option("--repo-username", metavar="USER", envvar="HELM_REPO_USERNAME",
              help="Username for Helm repo authentication.")
@click.option("--repo-password", metavar="PASS", envvar="HELM_REPO_PASSWORD",
              help="Password for Helm repo authentication.", hide_input=True)
@click.option("-f", "--values", "values_files", multiple=True, metavar="FILE",
              help="Values files passed to `helm template` for image discovery (repeatable).")
@click.option("--set", "set_values", multiple=True, metavar="KEY=VAL",
              help="--set overrides passed to `helm template` (repeatable).")
@click.option("--skip-images", is_flag=True, default=False,
              help="Bundle the chart only, without pulling images.")
@click.option("--include-image", "include_images", multiple=True, metavar="REF",
              help="Explicitly add an image to the bundle (repeatable).")
@click.option("--exclude-image", "exclude_images", multiple=True, metavar="PATTERN",
              help="Exclude images matching this substring (repeatable).")
@click.option("-v", "--verbose", is_flag=True, default=False, help="Enable debug logging.")
@click.pass_context
def pack_cmd(
    ctx: click.Context,
    chart: str,
    output: str,
    chart_version: str,
    repo_url: str,
    repo_name: str,
    repo_username: str,
    repo_password: str,
    values_files: tuple,
    set_values: tuple,
    skip_images: bool,
    include_images: tuple,
    exclude_images: tuple,
    verbose: bool,
) -> None:
    """
    Pack a Helm chart and its Docker images into an airgap bundle.

    \b
    CHART can be:
      - A chart reference in an already-added repo: bitnami/nginx
      - A chart name when --repo-url is given:      nginx
      - A local chart directory:                    ./my-chart/
      - A local .tgz archive:                       ./my-chart-1.0.0.tgz
      - An OCI reference:                           oci://registry.example.com/charts/nginx
    """
    _setup_logging(verbose)
    ctx.obj["verbose"] = verbose
    try:
        bundle = pack_module.pack(
            chart=chart,
            output=output,
            chart_version=chart_version or None,
            repo_url=repo_url or None,
            repo_name=repo_name or None,
            repo_username=repo_username or None,
            repo_password=repo_password or None,
            values_files=list(values_files) or None,
            set_values=list(set_values) or None,
            skip_images=skip_images,
            include_images=list(include_images) or None,
            exclude_images=list(exclude_images) or None,
        )
        click.echo(bundle)
    except Exception as e:
        click.secho(f"Error: {e}", fg="red", err=True)
        if ctx.obj.get("verbose"):
            raise
        sys.exit(1)


# ── install command ───────────────────────────────────────────────────────────

@cli.command("install")
@click.argument("bundle")
@click.argument("release_name")
@click.option("-n", "--namespace", default="default", show_default=True,
              help="Kubernetes namespace for the Helm release.")
@click.option("--registry", metavar="HOST:PORT",
              help="Private registry to push images to (e.g. myregistry.local:5000).")
@click.option("--registry-insecure", is_flag=True, default=False,
              help="Allow insecure (HTTP/no-TLS) registry.")
@click.option("-f", "--values", "values_files", multiple=True, metavar="FILE",
              help="Additional Helm values files (repeatable).")
@click.option("--set", "set_values", multiple=True, metavar="KEY=VAL",
              help="Additional --set overrides (repeatable).")
@click.option("--skip-load", is_flag=True, default=False,
              help="Skip loading images into local runtime.")
@click.option("--skip-push", is_flag=True, default=False,
              help="Skip pushing images to registry.")
@click.option("--skip-helm", is_flag=True, default=False,
              help="Only handle images; skip Helm install.")
@click.option("--no-create-namespace", is_flag=True, default=False,
              help="Do not pass --create-namespace to Helm.")
@click.option("--wait", is_flag=True, default=False,
              help="Pass --wait to Helm (blocks until rollout completes).")
@click.option("-v", "--verbose", is_flag=True, default=False, help="Enable debug logging.")
@click.pass_context
def install_cmd(
    ctx: click.Context,
    bundle: str,
    release_name: str,
    namespace: str,
    registry: str,
    registry_insecure: bool,
    values_files: tuple,
    set_values: tuple,
    skip_load: bool,
    skip_push: bool,
    skip_helm: bool,
    no_create_namespace: bool,
    wait: bool,
    verbose: bool,
) -> None:
    """
    Install a Helm chart from an airgap bundle.

    \b
    BUNDLE      : Path to the .tar.gz bundle created by `pack`
    RELEASE_NAME: Helm release name to use
    """
    _setup_logging(verbose)
    ctx.obj["verbose"] = verbose
    try:
        install_module.install(
            bundle_path=bundle,
            release_name=release_name,
            namespace=namespace,
            registry=registry or None,
            registry_insecure=registry_insecure,
            values_files=list(values_files) or None,
            set_values=list(set_values) or None,
            skip_load=skip_load,
            skip_push=skip_push,
            skip_helm=skip_helm,
            create_namespace=not no_create_namespace,
            wait=wait,
        )
    except Exception as e:
        click.secho(f"Error: {e}", fg="red", err=True)
        if ctx.obj.get("verbose"):
            raise
        sys.exit(1)


# ── inspect command ───────────────────────────────────────────────────────────

@cli.command("inspect")
@click.argument("bundle")
@click.option("--json", "as_json", is_flag=True, default=False, help="Output raw JSON manifest.")
@click.option("-v", "--verbose", is_flag=True, default=False, help="Enable debug logging.")
def inspect_cmd(bundle: str, as_json: bool, verbose: bool) -> None:
    """
    Inspect the contents of an airgap bundle without installing.

    \b
    BUNDLE : Path to the .tar.gz bundle
    """
    _setup_logging(verbose)
    try:
        manifest = install_module.list_bundle_contents(bundle)
    except Exception as e:
        click.secho(f"Error: {e}", fg="red", err=True)
        sys.exit(1)

    if as_json:
        click.echo(json.dumps(manifest, indent=2))
        return

    chart = manifest.get("chart", {})
    click.echo(f"Bundle created : {manifest.get('created_at', 'unknown')}")
    click.echo(f"Packager ver.  : {manifest.get('packager_version', 'unknown')}")
    click.echo(f"Chart          : {chart.get('name')} @ {chart.get('version')}")
    click.echo(f"Chart file     : {chart.get('filename')}")

    images = manifest.get("images", [])
    click.echo(f"\nImages ({len(images)}):")
    for img in images:
        status_sym = "✓" if img.get("status") == "ok" else "✗"
        click.echo(f"  [{status_sym}] {img['ref']}")
        click.echo(f"       file: {img['filename']}")

    failed = manifest.get("failed_images", [])
    if failed:
        click.secho(f"\nFailed images ({len(failed)}):", fg="yellow")
        for img in failed:
            click.secho(f"  {img}", fg="red")


def main() -> None:
    cli(obj={})


if __name__ == "__main__":
    main()
