#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# shellcheck source=dev/images.sh
. ./images.sh

CLUSTER=costgraph-selfhosted
NAMESPACE=${NAMESPACE:-costgraph}
RELEASE=${RELEASE:-costgraph}
KEY_FILE=${KEY_FILE:-./.key}

if [ ! -s "$KEY_FILE" ]; then
  echo "no deployment API key at $KEY_FILE" >&2
  echo "create one in the dashboard under Settings > API Keys, then:" >&2
  echo "  printf 'bl_...' > $KEY_FILE" >&2
  exit 1
fi
KEY=$(cat "$KEY_FILE")

if ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --config kind.yaml
fi
kubectl config use-context "kind-$CLUSTER"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl rollout status --namespace ingress-nginx \
  deployment/ingress-nginx-controller --timeout=300s

# Locally built images live in the host daemon, and a fresh cluster has none of
# them. Re-load rather than rebuild, in one call so the shared base layers are
# serialized once instead of per image. The operator images are loaded here too
# so the operator chart can be installed against this cluster afterwards.
present=()
for repo in "${LOCAL_IMAGE_REPOS[@]}"; do
  image=$(local_image_tag "$repo")
  docker image inspect "$image" >/dev/null 2>&1 && present+=("$image")
done
[ ${#present[@]} -gt 0 ] && kind load docker-image "${present[@]}" --name "$CLUSTER"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "$RELEASE" ../charts/costgraph-selfhosted \
  --namespace "$NAMESPACE" \
  -f kind-values.yaml \
  --set-string controlPlane.apiKey="$KEY" \
  ${EXTRA_HELM_ARGS:-} \
  --wait --timeout 10m

echo
echo "dashboard: http://costgraph.localtest.me:8088"
