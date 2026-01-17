# flac

# flac

Purpose
- Helper scripts to tag and manage FLAC files produced from MKV splits.

Files
- `tag_flacs.sh` — tag FLAC files in a directory using metadata defined in `tags.properties` (note: the file is named `tags.properties`).
- `tag_all.sh` — scan a directory tree (starting at the current working directory) for `tags.properties` files and run `tag_flacs.sh` inside each parent directory.
- `remove_flacs.sh` — remove `.flac` files under the current working directory (supports `--dry-run` and `--force`).

Usage
- Tag FLACs in a single album directory (the script looks for `tags.properties` in that directory):
  ```bash
  cd /path/to/album_dir
  ./tag_flacs.sh
  ```
- Tag across many subdirectories (dry-run):
  ```bash
  /path/to/scripts/flac/tag_all.sh --dry-run
  ```
  Remove `--dry-run` to perform tagging.

- Remove `.flac` files safely (dry-run):
  ```bash
  /path/to/scripts/flac/remove_flacs.sh --dry-run
  ```
  To actually delete, run without `--dry-run` and confirm, or use `--force` to skip confirmation.

Prerequisites
- Bash (`/usr/bin/env bash`) and standard Unix utilities.
- `metaflac` (from the `flac` package) is required by `tag_flacs.sh` to write tags. Install on macOS with `brew install flac`.

Notes
- The properties filename used by `tag_flacs.sh` is `tags.properties` (plural). Ensure your metadata file is named accordingly and includes tag key/value lines like:
  ```text
  ARTIST=Propaganda
  ALBUM=A Secret Wish
  DATE=2025-10-31
  TRACK_OFFSET=10
  ```
- `tag_all.sh` searches from the current working directory for `tags.properties` files; run it from whichever top-level folder you want scanned.
- `remove_flacs.sh` will remove all `.flac` files under the current working directory and its children — prefer `--dry-run` first.

If you want examples or additional fields supported in `tags.properties`, tell me which tags you'd like documented and I'll add them.
