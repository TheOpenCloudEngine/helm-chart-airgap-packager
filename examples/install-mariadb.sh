#!/usr/bin/env bash
# Example: Install MariaDB 10.6.12 from an airgap bundle
#
# Prerequisites (on airgap machine):
#   - helm CLI installed
#   - docker or podman installed and running
#   - kubectl configured to reach the cluster
#   - A private registry running at myregistry.local:5000

source "$(dirname "$0")/config.sh"

BUNDLE="${OUTPUT_DIR}/mariadb-11.5.7-airgap.tar.gz"
RELEASE="mariadb"
NAMESPACE="database"

echo "==> Bundle contents:"
helm-airgap inspect "$BUNDLE"

echo ""
echo "==> Installing MariaDB..."
helm-airgap install "$BUNDLE" "$RELEASE" \
  --namespace "$NAMESPACE" \
  --registry "$REGISTRY" \
  --set "auth.rootPassword=changeme" \
  --set "auth.database=mydb" \
  --set "auth.username=myuser" \
  --set "auth.password=mypassword" \
  --set "primary.persistence.size=10Gi" \
  --wait \
  -v

echo ""
echo "Done! MariaDB release '$RELEASE' deployed in namespace '$NAMESPACE'."
echo ""
echo "Connect to MariaDB:"
echo "  kubectl exec -it ${RELEASE}-0 -n ${NAMESPACE} -- mysql -u root -p"
echo "  Service endpoint: ${RELEASE}.${NAMESPACE}.svc.cluster.local:3306"
echo ""
echo "Retrieve root password:"
echo "  kubectl get secret ${RELEASE} -n ${NAMESPACE} -o jsonpath='{.data.mariadb-root-password}' | base64 -d"
