#!/usr/bin/env bash

set -euo pipefail

# Usage: tag_all.sh [--dry-run]
#
# Finds every subdirectory under the cwd that contains
# a file named "tag.properties" and runs the adjacent `tag_flacs.sh`
# script from within each of those directories.

DRY_RUN=0
if [[ ${1:-} == "--dry-run" || ${1:-} == "-n" ]]; then
  DRY_RUN=1
fi

# Current working directory to search for `tag.properties` (what $CWD should be)
CWD="$(pwd)"

# Directory where this script (and tag_flacs.sh) live
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG_SCRIPT="$DIR/tag_flacs.sh"

if [[ ! -f "$TAG_SCRIPT" ]]; then
  echo "Error: $TAG_SCRIPT not found." >&2
  exit 1
fi

# Inform where we'll search
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run: will search under $CWD for tag.properties and show actions"
fi

# Find tag.properties files and iterate over their parent directories
while IFS= read -r -d '' propfile; do
  target_dir=$(dirname "$propfile")

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would run tag_flacs.sh in: $target_dir"
    continue
  fi

  echo "Running tag_flacs.sh in: $target_dir"
  # Run the tag script from within the target directory. Prefer direct
  # execution if the script is executable; otherwise run it with bash.
  (
    cd "$target_dir" || exit 1
    if [[ -x "$TAG_SCRIPT" ]]; then
      "$TAG_SCRIPT"
    else
      bash "$TAG_SCRIPT"
    fi
  )
done < <(find "$CWD" -type f -name tags.properties -print0)

echo "All done."
