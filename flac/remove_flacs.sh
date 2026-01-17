#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run|-n] [--force|-f] [--help|-h]

Removes all .flac files under the current working directory and its children.

Options:
  --dry-run, -n   Show files that would be removed and exit
  --force, -f     Remove without confirmation
  --help, -h      Show this help
EOF
}

DRY_RUN=0
FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift ;;
    --force|-f) FORCE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

CWD="$(pwd)"

files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find "$CWD" -type f -iname '*.flac' -print0)

count=${#files[@]}
if [[ $count -eq 0 ]]; then
  echo "No .flac files found under: $CWD"
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run: $count .flac files found under: $CWD"
  for f in "${files[@]}"; do
    echo "  $f"
  done
  exit 0
fi

if [[ $FORCE -ne 1 ]]; then
  printf "About to delete %d .flac files under: %s\n" "$count" "$CWD"
  read -r -p "Continue? [y/N] " ans
  case "$ans" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

echo "Deleting $count .flac files..."
for f in "${files[@]}"; do
  rm -v -- "$f"
done

echo "Done."
