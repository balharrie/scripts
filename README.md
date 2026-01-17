# scripts

Collection of small media-processing helper scripts.

Top-level layout
- `flac/` — scripts to tag FLAC files (see flac/README.md).
- `mkv/`  — scripts to split MKV audio tracks by chapter (see mkv/README.md).

General notes
- These are standalone bash scripts intended to be run from the shell.
- Many scripts expect common CLI tools to be installed (Homebrew packages on macOS): `ffmpeg`, `mkvtoolnix` (`mkvmerge`/`mkvextract`), and `jq`.
- If you run tools on external volumes, prefer using the `--dry-run` options first where available.

If you want help running a specific script, open the relevant README under `flac/` or `mkv/`.
