#!/usr/bin/env bash

# Check for input file
if [ -z "$1" ]; then
    echo "Usage: $0 <file.mkv>"
    exit 1
fi

FILE="$1"

echo "Scanning audio tracks in: $FILE"
echo

# List audio tracks with IDs
mkvmerge -i "$FILE" | grep "audio" | nl -w2 -s": "

echo
echo "Above are the audio tracks found."
echo "Enter the TRACK ID (not the number on the left) you want as default."
echo "Example: 1 or 2 or 3"
read -p "Default audio track ID: " DEFAULT_ID

echo
echo "Setting track $DEFAULT_ID as default..."

# Get all audio track IDs
AUDIO_IDS=$(mkvmerge -i "$FILE" | grep "audio" | sed -E 's/Track ID ([0-9]+).*/\1/')

# Loop through all audio tracks and set flags
for ID in $AUDIO_IDS; do
    if [ "$ID" = "$DEFAULT_ID" ]; then
        echo " → Setting track $ID as default"
        mkvpropedit "$FILE" --edit track:a$ID --set flag-default=1
    else
        echo " → Clearing default flag on track $ID"
        mkvpropedit "$FILE" --edit track:a$ID --set flag-default=0
    fi
done

echo
echo "Done! Default audio track updated."
