#!/usr/bin/env bash
# The components published for linux/amd64 only, and the local tag each is
# built and loaded under. Sourced by build-local-images.sh and up.sh so a
# built image can never be named differently from the one that gets loaded.
LOCAL_IMAGE_REPOS=(aggregator ingestion-api costgraph-operator-kubernetes costgraph-operator-prometheus)

local_image_tag() {
  printf 'costgraph-local/%s:dev' "${1#costgraph-}"
}
