# flac

Purpose
- Helper scripts to tag, rename, remove and copy FLAC files produced from MKV splits.

Scripts
- `tag_flacs.sh` — tag FLAC files in a directory using metadata in `tags.properties`.
- `tag_all.sh` — scan a directory tree (from the current working directory) for `tags.properties` files and run `tag_flacs.sh` in each parent directory. Supports `--dry-run`.
- `remove_flacs.sh` — remove `.flac` files under the current working directory and children. Supports `--dry-run` and `--force`.
- `rename_flacs_by_tag.sh` — rename `.flac` files in the current directory so the leading number is taken from the file's `TRACKNUMBER` tag; preserves bracketed tokens. Supports `--dry-run` and `--force`.
- `rename_flacs_recursive.sh` — find directories containing `.flac` files under the current working directory and run `rename_flacs_by_tag.sh` in each (for bulk renaming). Supports `--dry-run` and `--force`.
- `copy_flacs.sh` — recursively copy `.flac` files from the current working directory into a destination directory, preserving relative paths. Supports `--dry-run` and `--skip-existing` (do not overwrite existing files).

Usage examples
- Tag a single album (requires `tags.properties` in directory):
  ```bash
  cd /path/to/album_dir
  ./tag_flacs.sh
  ```
- Tag many directories (dry-run):
  ```bash
  /path/to/scripts/flac/tag_all.sh --dry-run
  ```
- Rename FLACs in a directory (dry-run):
  ```bash
  /path/to/scripts/flac/rename_flacs_by_tag.sh --dry-run
  ```
- Rename FLACs recursively (delegates to the per-directory script):
  ```bash
  /path/to/scripts/flac/rename_flacs_recursive.sh --dry-run
  ```
- Copy FLACs to a destination (preserve structure):
  ```bash
  /path/to/scripts/flac/copy_flacs.sh --dry-run /Volumes/Backup/flacs
  ```

Prerequisites
- Bash (`/usr/bin/env bash`) and common Unix utilities (`find`, `cp`, `mv`).
- `metaflac` (from the `flac` package) is required by `tag_flacs.sh` and `rename_flacs_by_tag.sh` for reading/writing tags — install with `brew install flac` on macOS.
- `ffmpeg`, `mkvtoolnix` (`mkvmerge`, `mkvextract`) and `jq` are required for `mkv/*` scripts that produce the FLACs in the first place.

Notes
- Where available, scripts support `--dry-run` to preview actions without making changes — prefer dry-run when operating on external volumes.
- `rename_flacs_by_tag.sh` is intentionally limited to a single directory; use `rename_flacs_recursive.sh` to run it across a tree.
- `copy_flacs.sh` preserves the directory structure relative to the current working directory. If you prefer a flattening option (all files into one target directory), I can add it.

If you want sample `tags.properties` templates or more detailed examples, tell me which script to expand.
