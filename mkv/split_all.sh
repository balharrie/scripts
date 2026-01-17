#!/usr/bin/env bash

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for mkv in *.mkv; do
  [ -e "$mkv" ] || continue
  echo "=== $mkv ==="
  "$DIR/split_tracks.sh" "$mkv"
  echo
done
