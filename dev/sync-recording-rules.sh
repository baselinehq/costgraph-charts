#!/usr/bin/env bash
# The aggregator owns the recording rules; this chart carries a copy because
# Helm cannot reference files outside the chart directory and the two live in
# different repos. Run with -check to fail on drift, or without to re-copy.
set -euo pipefail

cd "$(dirname "$0")"

SOURCE=${SOURCE:-../../aggregator/deploy/recording-rules}
DEST=../charts/costgraph-selfhosted/recording-rules

[ -d "$SOURCE" ] || { echo "no aggregator checkout at $SOURCE" >&2; exit 1; }

if [ "${1:-}" = "-check" ]; then
  for set in long short; do
    diff -r "$SOURCE/$set" "$DEST/$set" || {
      echo "recording rules have drifted from $SOURCE - run $0 to re-copy" >&2
      exit 1
    }
  done
  echo "recording rules match $SOURCE"
  exit 0
fi

for set in long short; do
  rm -rf "${DEST:?}/$set"
  cp -r "$SOURCE/$set" "$DEST/$set"
done
echo "copied $SOURCE -> $DEST"
