#!/usr/bin/env bash

set -euo pipefail

usage(){
  cat <<EOF
Usage: $(basename "$0") [--dry-run|-n] [--force|-f]

Rename .flac files in the current directory so the leading number is the
track number taken from the file's tags (TRACKNUMBER). Bracketed parts
from the original filename (e.g. (Atmos) or [Live]) are preserved.

Examples:
  # dry-run (show rename actions)
  $(basename "$0") --dry-run

  # actually rename, prompt if collision
  $(basename "$0")

  # force overwrite if target exists
  $(basename "$0") --force

Resulting filename examples: 43_(Atmos).flac or 3_[Live]_(Atmos).flac
EOF
}

DRY_RUN=0
FORCE=0
while [[ ${1:-} != "" ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift;;
    --force|-f) FORCE=1; shift;;
    --help|-h) usage; exit 0;;
    --) shift; break;;
    *) echo "Unknown option: $1" >&2; usage; exit 2;;
  esac
done

CWD="$(pwd)"

# Collect files in current directory (non-recursive)
files=()
for f in ./*.flac; do
  [[ -f "$f" ]] || continue
  files+=("$f")
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No .flac files found in: $CWD"
  exit 0
fi

if ! command -v metaflac >/dev/null 2>&1; then
  echo "Error: metaflac not found. Install flac (e.g. brew install flac)." >&2
  exit 1
fi

for src in "${files[@]}"; do
  base=$(basename -- "$src")
  ext="${base##*.}"
  name_noext="${base%.*}"

  # Read TRACKNUMBER tag(s)
  track_raw=$(metaflac --show-tag=TRACKNUMBER "$src" 2>/dev/null | sed -n 's/^TRACKNUMBER=//p' | head -n1 || true)
  if [[ -z "$track_raw" ]]; then
    echo "Skipping $base: TRACKNUMBER tag not found"
    continue
  fi

  # Extract numeric portion
  track_num=$(echo "$track_raw" | grep -oE '[0-9]+' || true)
  if [[ -z "$track_num" ]]; then
    echo "Skipping $base: TRACKNUMBER tag has no digits: '$track_raw'"
    continue
  fi

  # Find bracketed tokens (parentheses or square brackets) in the original filename
  mapfile -t brackets < <(echo "$name_noext" | grep -oE '\([^)]*\)|\[[^]]*\]' || true)

  suffix=""
  if [[ ${#brackets[@]} -gt 0 ]]; then
    # join with underscores, preserve original brackets
    for tok in "${brackets[@]}"; do
      # normalize whitespace around token
      tok_trim=$(echo "$tok" )
      suffix+="_${tok_trim}"
    done
  fi

  newbase="${track_num}${suffix}.${ext}"
  newpath="$(dirname "$src")/$newbase"

  if [[ "$src" == "$newpath" ]]; then
    echo "Already named: $base"
    continue
  fi

  if [[ -e "$newpath" && $FORCE -ne 1 ]]; then
    echo "Target exists: $newbase (skipping). Use --force to overwrite."
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ $FORCE -eq 1 ]]; then
      echo "DRY-RUN: mv -f -- '$src' '$newpath'"
    else
      echo "DRY-RUN: mv -- '$src' '$newpath'"
    fi
  else
    if [[ $FORCE -eq 1 ]]; then
      mv -f -- "$src" "$newpath"
    else
      mv -- "$src" "$newpath"
    fi
    echo "Renamed: $base -> $newbase"
  fi
done

echo "Done."
