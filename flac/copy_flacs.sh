#!/usr/bin/env bash

set -euo pipefail

usage(){
  cat <<EOF
Usage: $(basename "$0") [--dry-run|-n] [--skip-existing|-k] DEST_DIR

Recursively copy all .flac files from the current working directory and its
children into DEST_DIR, preserving the directory structure relative to CWD.

Options:
  --dry-run, -n       Show what would be copied without performing the copy
  --skip-existing, -k Do not overwrite files that already exist at the destination
  --help, -h          Show this help

Examples:
  # dry-run to /mnt/backup
  $(basename "$0") --dry-run /mnt/backup

  # actually copy, skipping existing files
  $(basename "$0") --skip-existing /mnt/backup
EOF
}

DRY_RUN=0
SKIP_EXISTING=0
while [[ ${1:-} != "" && ${1:0:1} == "-" ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift;;
    --skip-existing|-k) SKIP_EXISTING=1; shift;;
    --help|-h) usage; exit 0;;
    --) shift; break;;
    *) echo "Unknown option: $1" >&2; usage; exit 2;;
  esac
done

DEST_DIR="${1:-}"
if [[ -z "$DEST_DIR" ]]; then
  echo "Destination directory required." >&2
  usage
  exit 2
fi

# Normalize DEST_DIR to absolute path
DEST_DIR="$(cd "$DEST_DIR" 2>/dev/null && pwd || printf '%s' "$DEST_DIR")"

CWD="$(pwd)"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "DRY-RUN: copying .flac files found under: $CWD -> $DEST_DIR"
fi

found=0
while IFS= read -r -d '' src; do
  found=1
  # compute path relative to CWD
  relpath=${src#${CWD}/}
  dest="$DEST_DIR/$relpath"

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ -e "$dest" && $SKIP_EXISTING -eq 1 ]]; then
      echo "DRY-RUN: skip existing -> $dest"
    else
      echo "DRY-RUN: copy '$src' -> '$dest'"
    fi
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && $SKIP_EXISTING -eq 1 ]]; then
    echo "Skipping existing: $dest"
    continue
  fi

  cp -p -- "$src" "$dest"
  echo "Copied: $src -> $dest"
done < <(find "$CWD" -type f -iname '*.flac' -print0)

if [[ $found -eq 0 ]]; then
  echo "No .flac files found under: $CWD"
fi

echo "Done."
