#!/usr/bin/env bash

# Usage: ./subtitle-set-forced.sh movie.mkv <track_id>
# Example: ./subtitle-set-forced.sh movie.mkv 2
# Requires: mkvpropedit (from MKVToolNix)

FILE="$1"
TRACK_ID="$2"
FORCED="$3"

if [[ -z "$FILE" || -z "$TRACK_ID" ]]; then
  echo "Usage: $0 <file.mkv> <subtitle_track_id>"
  exit 1
fi

if ! command -v mkvpropedit &>/dev/null; then
  echo "Error: mkvpropedit not found. Install MKVToolNix."
  exit 1
fi

echo "Setting forced and default display flags on subtitle track $TRACK_ID in $FILE..."

# Apply flags
mkvpropedit "$FILE" \
  --edit track:$TRACK_ID \
  --set flag-forced=$FORCED \
  --set flag-default=$FORCED

if [[ $? -eq 0 ]]; then
  echo "✅ Subtitle track $TRACK_ID updated successfully."
  echo "   - Forced flag: enabled"
  echo "   - Default (display) flag: enabled"
else
  echo "❌ Failed to update subtitle track $TRACK_ID."
fi
