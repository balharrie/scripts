# mkv

Purpose
- Scripts to split audio tracks out of MKV files and export per-chapter audio files.

Files
- `split_all.sh` — iterates over `*.mkv` files in the script directory and calls `split_tracks.sh` for each. The script runs relative to its own directory so it works when invoked from elsewhere.
- `split_tracks.sh` — inspects an MKV with `mkvmerge`/`mkvextract` and `jq` to detect audio tracks and chapters, then uses `ffmpeg` to export each audio track by chapter.

Usage
- Split all MKVs in the script directory:
  ```bash
  /path/to/scripts/mkv/split_all.sh
  ```
- Split a single MKV (from the `mkv/` directory or by path):
  ```bash
  /path/to/scripts/mkv/split_tracks.sh "/path/to/file.mkv"
  ```

Prerequisites
- `mkvtoolnix` (provides `mkvmerge`, `mkvextract`) — e.g. `brew install mkvtoolnix`.
- `ffmpeg` — e.g. `brew install ffmpeg`.
- `jq` — for parsing mkvmerge JSON output.

Notes
- `split_tracks.sh` uses `ffmpeg -ss` with `-to` to extract per-chapter segments and may transcode depending on track codecs (some codecs use `-c copy`).
- Check execute permissions (`chmod +x`) if a script doesn't run; `split_all.sh` now invokes `split_tracks.sh` by absolute path based on the script directory to avoid CWD issues.
