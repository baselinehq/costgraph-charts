#!/usr/bin/env bash
# Renders the chart and asserts the naming invariants the CronJob name depends
# on. There is no helm unit-test harness in this repo, so run this by hand from
# the chart directory: tests/naming.sh
set -euo pipefail

cd "$(dirname "$0")/.."
helm dependency build . >/dev/null

render() {
  helm template t . \
    --set costgraph.apiKey=k --set costgraph.connectionId=c --set imagePullSecret.apiKey=k \
    "$@" \
    | awk '/kind: CronJob/{f=1} f&&/^  name:/{print $2; exit}'
}

# A name within the cap is used verbatim.
short=$(render)
[ "$short" = "t-focus-exporter" ] || { echo "short name changed: $short" >&2; exit 1; }

# The CronJob name never exceeds 52, so the Job the controller spawns stays
# within the 63-character limit.
long=$(render --set fullnameOverride="$(printf 'a%.0s' {1..60})")
[ "${#long}" -le 52 ] || { echo "name over 52: ${#long}" >&2; exit 1; }

# Two overrides that share their first 52 characters still render distinct
# names, so two releases cannot address the same CronJob.
a=$(render --set fullnameOverride="$(printf 'a%.0s' {1..52})b")
b=$(render --set fullnameOverride="$(printf 'a%.0s' {1..52})c")
[ "$a" != "$b" ] || { echo "colliding overrides render the same name: $a" >&2; exit 1; }

echo "naming invariants hold"
