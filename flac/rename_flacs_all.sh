#!/usr/bin/env bash

set -euo pipefail

usage(){
  cat <<EOF
Usage: $(basename "$0") [--dry-run|-n] [--force|-f]

Find all directories under the current working directory that contain .flac files
and run the local rename script (`rename_flacs_by_tag.sh`) inside each directory.
This script does not rename recursively itself; it delegates to the per-directory
script so naming behaviour is consistent.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INNER_SCRIPT="$SCRIPT_DIR/rename_flacs_by_tag.sh"

if [[ ! -x "$INNER_SCRIPT" && ! -f "$INNER_SCRIPT" ]]; then
  echo "Error: $INNER_SCRIPT not found. Ensure rename_flacs_by_tag.sh is present." >&2
  exit 1
fi

dirs=()
# Find directories containing .flac files (non-recursive per-directory detection)
while IFS= read -r -d '' f; do
  dirs+=("$(dirname "$f")")
done < <(find "$CWD" -type f -iname '*.flac' -print0)

if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "No .flac-containing directories found under: $CWD"
  exit 0
fi

# Deduplicate and sort directories
mapfile -t uniq_dirs < <(printf '%s\n' "${dirs[@]}" | sort -u)

for d in "${uniq_dirs[@]}"; do
  echo "Processing directory: $d"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  DRY-RUN: would run $INNER_SCRIPT in $d"
    # Show what flags would be forwarded
    flags=( )
    [[ $DRY_RUN -eq 1 ]] && flags+=(--dry-run)
    [[ $FORCE -eq 1 ]] && flags+=(--force)
    if [[ ${#flags[@]} -gt 0 ]]; then
      echo "    DRY-RUN: $INNER_SCRIPT ${flags[*]}"
    else
      echo "    DRY-RUN: $INNER_SCRIPT"
    fi
    continue
  fi

  (cd "$d" && {
    if [[ $FORCE -eq 1 ]]; then
      "$INNER_SCRIPT" --force
    else
      "$INNER_SCRIPT"
    fi
  })
done

echo "All done."
