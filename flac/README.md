# flac

Purpose
- Helper scripts to tag FLAC files that were exported from MKV splits.

Files
- `tag_flacs.sh` — tags FLAC files in the current directory using metadata defined in `tag.properties`.
- `tag_all.sh` — scans a directory tree (from the current working directory) for subdirectories containing `tag.properties` and runs `tag_flacs.sh` inside each.

Usage
- Tag FLACs in the current directory:
  ```bash
  cd /path/to/album_dir
  ./tag_flacs.sh
  ```
- Tag across many subdirectories (dry-run):
  ```bash
  /path/to/scripts/flac/tag_all.sh --dry-run
  ```
  Remove `--dry-run` to perform tagging.

Prerequisites
- Bash (`/usr/bin/env bash`), standard Unix utilities.
- `metaflac` or other tagging utilities used by `tag_flacs.sh` (see header of that script for exact requirements).

Notes
- `tag_all.sh` searches from the current working directory for `tag.properties` files; run it from whichever top-level folder you want scanned.
