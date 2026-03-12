#!/usr/bin/env bash
# Example: Install Apache Airflow 3.1.7 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

BUNDLE="./bundles/airflow-1.19.0-airgap.tar.gz"
RELEASE="airflow"
NAMESPACE="airflow"
REGISTRY="myregistry.local:5000"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing Apache Airflow..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --wait \
  -v

echo ""
echo "Done! Airflow release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Access the Airflow Web UI:"
echo "  kubectl port-forward svc/${RELEASE}-webserver 8080:8080 -n ${NAMESPACE}"
echo "  Default credentials: admin / admin"
