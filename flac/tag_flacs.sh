#!/opt/homebrew/bin/bash

# Usage: ./tag_flac_files.sh [directory]
# Looks for tags.properties in the directory and tags all FLAC files

set -u

DIR="${1:-.}"

if [[ ! -d "$DIR" ]]; then
    echo "Error: Directory '$DIR' not found"
    exit 1
fi

PROPS_FILE="$DIR/tags.properties"

if [[ ! -f "$PROPS_FILE" ]]; then
    echo "Error: tags.properties not found in $DIR"
    echo "Create a file with tags like:"
    echo "  ARTIST=Propaganda"
    echo "  ALBUM=A Secret Wish"
    echo "  DATE=2025-10-31"
    echo "  TRACK_OFFSET=10"
    exit 1
fi

if ! command -v metaflac >/dev/null 2>&1; then
    echo "Error: metaflac not found. Install flac (e.g. brew install flac)"
    exit 1
fi

# Read properties file into associative array
declare -A TAGS
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    TAGS["$key"]="$value"
done < "$PROPS_FILE"

echo "Loaded tags from $PROPS_FILE:"
for key in "${!TAGS[@]}"; do
    echo "  $key=${TAGS[$key]}"
done
echo

# Process all FLAC files
count=0
for file in "$DIR"/*.flac; do
    [[ ! -f "$file" ]] && continue
    
    filename=$(basename "$file")
    
    # Extract track number from filename (assumes NN_ prefix)
    track_num=$(echo "$filename" | grep -oE '^[0-9]+')
    
    if [[ -z "$track_num" ]]; then
        echo "Warning: Could not extract track number from $filename, skipping"
        continue
    fi
    
    # Remove leading zeros for the tag
    track_num=$((10#$track_num))
    
    # Add TRACK_OFFSET if present in tags.properties
    if [[ -n "${TAGS[TRACK_OFFSET]:-}" ]]; then
        track_offset=$((TAGS[TRACK_OFFSET]))
        track_num=$((track_num + track_offset))
    fi
    
    echo "Tagging: $filename"
    echo "  Track number: $track_num"
    
    # Build metaflac command
    cmd=(metaflac)

    cmd+=(--remove-all-tags)
    
    # Add track number
    cmd+=(--set-tag="TRACKNUMBER=$track_num")
    
    # Add MusicBrainz track ID if MUSICBRAINZ_TRACKID_BASE is set
    # This allows per-track IDs by appending track number offset
    if [[ -n "${TAGS[MUSICBRAINZ_TRACKID_BASE]:-}" && -n "${TAGS[MUSICBRAINZ_TRACKID_OFFSET]:-}" ]]; then
        base_track=$((TAGS[MUSICBRAINZ_TRACKID_OFFSET]))
        actual_track=$((base_track + track_num - 1))
        # Note: You'd need to look up the actual recording ID for each track
        # This is just a placeholder for the pattern
        echo "  MusicBrainz track offset: $actual_track"
    fi
    
    # Add all tags from properties file
    for key in "${!TAGS[@]}"; do
        cmd+=(--set-tag="${key}=${TAGS[$key]}")
        echo "  $key: ${TAGS[$key]}"
    done
    
    # Execute
    "${cmd[@]}" "$file"
    
    ((count++))
    echo
done

echo "Tagged $count FLAC file(s)"

