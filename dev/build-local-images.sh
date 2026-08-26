#!/usr/bin/env bash
# aggregator, ingestion-api and both operator components publish linux/amd64
# only, so on an arm64 host their pods land in ImagePullBackOff with "no match
# for platform in manifest". Build them from the monorepo for this host's
# architecture instead.
set -euo pipefail

cd "$(dirname "$0")"

# shellcheck source=dev/images.sh
. ./images.sh

MONOREPO=${MONOREPO:-../..}
case "$(uname -m)" in
  arm64 | aarch64) ARCH=arm64 ;;
  *) ARCH=amd64 ;;
esac

GITHUB_USER=$(gh api user -q .login)
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
gh auth token > "$BUILD_DIR/token"

build() {
  local repo=$1 tag=$2
  local ctx="$MONOREPO/$repo"
  [ -d "$ctx" ] || { echo "missing $ctx" >&2; exit 1; }
  sed "s/GOARCH=amd64/GOARCH=$ARCH/" "$ctx/Dockerfile" > "$BUILD_DIR/$repo.Dockerfile"
  docker build \
    --file "$BUILD_DIR/$repo.Dockerfile" \
    --build-arg GITHUB_USER="$GITHUB_USER" \
    --secret id=github_token,src="$BUILD_DIR/token" \
    --tag "$tag" \
    "$ctx"
}

# The four builds share nothing, so wall clock is the slowest one rather than
# the sum. Bare `wait` always exits 0, so each build is waited on by pid to
# keep a failure from passing as success.
pids=()
for repo in "${LOCAL_IMAGE_REPOS[@]}"; do
  build "$repo" "$(local_image_tag "$repo")" &
  pids+=("$!")
done

failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || failed=1
done
[ "$failed" -eq 0 ] || { echo "one or more image builds failed" >&2; exit 1; }
