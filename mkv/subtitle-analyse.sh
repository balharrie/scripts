#!/usr/bin/env bash

# Usage: ./subtitle-analyse.sh movie.mkv
# Requires: mkvmerge, mkvinfo, grep, awk

FILE="$1"

if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <file.mkv>"
  exit 1
fi

if ! command -v mkvmerge &>/dev/null; then
  echo "Error: mkvmerge not found. Install MKVToolNix."
  exit 1
fi

echo "Analyzing subtitle tracks in: $FILE"
echo "--------------------------------------------------"

# List subtitle tracks with mkvmerge
mkvmerge -i "$FILE" | grep "subtitles" | while read -r line; do
  track_id=$(echo "$line" | awk -F: '{print $1}' | awk '{print $3}')
  codec=$(echo "$line" | awk -F: '{print $2}' | sed 's/^ //')

  echo "Track ID: $track_id | Codec: $codec"

  # Extract first 200 lines of subtitle text for inspection
  mkvextract tracks "$FILE" "$track_id:track_$track_id.srt" &>/dev/null

  if [[ -f "track_$track_id.srt" ]]; then
    # Heuristic: look for common markers of forced subs
    if grep -qiE "(foreign|translated|forced|only)" track_$track_id.srt; then
      echo "  -> Candidate forced subtitles (keywords found)"
    else
      # Check if very few lines exist (often forced subs are short)
      line_count=$(wc -l < track_$track_id.srt)
      if [[ $line_count -lt 300 ]]; then
        echo "  -> Candidate forced subtitles (short length: $line_count lines)"
      else
        echo "  -> Likely full subtitles"
      fi
    fi
    # rm -f track_$track_id.srt
  else
    echo "  -> Could not extract text for analysis"
  fi
done