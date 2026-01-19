#!/opt/homebrew/bin/bash

# Usage: ./split_audio_tracks.sh [--dry-run|-n] "input.mkv"

set -u

# Parse options: support --dry-run|-n
DRY_RUN=0
while [[ "${1:-}" =~ ^- && ! "${1:-}" == "--" ]]; do
    case "$1" in
        --dry-run|-n) DRY_RUN=1; shift ;;
        --help|-h) echo "Usage: $0 [--dry-run|-n] input.mkv"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
if [[ "${1:-}" == "--" ]]; then shift; fi

INPUT="${1:-}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 [--dry-run|-n] input.mkv"
    exit 1
fi

if ! command -v mkvmerge >/dev/null 2>&1; then
    echo "mkvmerge not found. Install mkvtoolnix (e.g. brew install mkvtoolnix)."
    exit 1
fi

if ! command -v mkvextract >/dev/null 2>&1; then
    echo "mkvextract not found. Install mkvtoolnix (e.g. brew install mkvtoolnix)."
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg not found. Install ffmpeg (e.g. brew install ffmpeg)."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. Install jq (e.g. brew install jq)."
    exit 1
fi

BASENAME=$(basename "$INPUT")
BASENAME_NOEXT="${BASENAME%.*}"

echo "Input file: $INPUT"

# Extract `t` and `z` numbers from the input basename if present.
# Example basename: "..._t01 ... _track_2" -> t_num=1, z_num=2
t_num=0
z_num=0
if [[ "$BASENAME_NOEXT" =~ _t([0-9]+) ]]; then
    # remove leading zeros safely
    t_num=$((10#${BASH_REMATCH[1]}))
fi

########################################
# Extract chapters and build timestamp array
########################################

CHAPTER_FILE=$(mktemp -t chaptersXXXX.txt)

echo "Extracting chapters..."
mkvextract chapters "$INPUT" --simple > "$CHAPTER_FILE"

# Collect chapter start times into an array
CHAPTER_STARTS=()
while IFS= read -r line; do
    # Lines look like: CHAPTER01=00:00:00.000000000
    ts=$(echo "$line" | cut -d= -f2)
    if [[ -n "$ts" ]]; then
        CHAPTER_STARTS+=("$ts")
    fi
done < <(grep -E '^CHAPTER[0-9]+=' "$CHAPTER_FILE")

NUM_CHAPTERS=${#CHAPTER_STARTS[@]}
echo "Found $NUM_CHAPTERS chapters"

if [[ "$NUM_CHAPTERS" -eq 0 ]]; then
    echo "No chapters found — will export whole tracks as single files."
    # Use a single-start at 00:00:00 so extraction exports the full track
    CHAPTER_STARTS=("00:00:00")
    NUM_CHAPTERS=1
fi

########################################
# Get audio track info via mkvmerge JSON + jq
########################################

TRACK_INFO_FILE=$(mktemp -t tracksXXXX.txt)

echo "Detecting audio tracks..."
mkvmerge -J "$INPUT" \
  | jq -r '
      .tracks[]
      | select(.type=="audio")
      | "\(.id) \(.codec) \(.properties.audio_channels // 0)"
    ' > "$TRACK_INFO_FILE"

if [[ ! -s "$TRACK_INFO_FILE" ]]; then
    echo "No audio tracks found. Exiting."
    rm -f "$CHAPTER_FILE" "$TRACK_INFO_FILE"
    exit 1
fi

echo "Audio tracks (id codec channels):"
cat "$TRACK_INFO_FILE"
echo

########################################
# Helper: map channel count to label like 2.0, 5.1, 7.1
########################################
channel_layout_label() {
    local ch="$1"
    case "$ch" in
        1)  echo "1.0" ;;
        2)  echo "2.0" ;;
        3)  echo "2.1" ;;
        4)  echo "4.0" ;;
        5)  echo "5.0" ;;
        6)  echo "5.1" ;;
        7)  echo "6.1" ;;
        8)  echo "7.1" ;;
        *)  echo "${ch}" ;;
    esac
}

########################################
# Process each audio track
########################################

while IFS= read -r line; do
    # Each line: "<id> <codec> <channels>"
    tid=$(echo "$line" | awk '{print $1}')
    codec=$(echo "$line" | awk '{print $2}')
    channels=$(echo "$line" | awk '{print $3}')

    if [[ -z "$tid" ]]; then
        continue
    fi

    ch_label=$(channel_layout_label "$channels")

    # Decide output codec, ffmpeg codec, extension, and human tag
    ff_codec="flac"
    ext="flac"
    tag="flac"

    case "$codec" in
        A_TRUEHD*)
            ff_codec="copy"
            ext="thd"
            tag="truehd"
            ;;
        A_DTS*|A_DTSHD*)
            ff_codec="copy"
            ext="dts"
            tag="dtshd"
            ;;
        A_FLAC*)
            ff_codec="flac"
            ext="flac"
            tag="flac"
            ;;
        A_PCM*|A_PCM/INT/*|A_PCM/FLOAT/*)
            # LPCM -> FLAC (lossless)
            ff_codec="flac"
            ext="flac"
            tag="flac"
            ;;
        *)
            # Other codecs (AC-3, E-AC-3, etc.) -> FLAC for consistency
            ff_codec="flac"
            ext="flac"
            tag="flac"
            ;;
    esac

    OUTDIR="${BASENAME_NOEXT}_track_${tid}"
    mkdir -p "$OUTDIR"

    # Determine z_num as the trailing number of the output directory (fallback to tid)
    if [[ "$OUTDIR" =~ _([0-9]+)$ ]]; then
        z_num=$((10#${BASH_REMATCH[1]}))
    else
        z_num=$((10#$tid))
    fi

    echo "----------------------------------------"
    echo "Track ID:     $tid"
    echo "Codec:        $codec"
    echo "Channels:     $channels ($ch_label)"
    echo "Output codec: $tag (ffmpeg: $ff_codec, ext: .$ext)"
    echo "Output dir:   $OUTDIR"
    echo

    # Loop over chapters
    for ((i=0; i<NUM_CHAPTERS; i++)); do
        START="${CHAPTER_STARTS[$i]}"
        if (( i + 1 < NUM_CHAPTERS )); then
            END="${CHAPTER_STARTS[$((i+1))]}"
        else
            END=""
        fi

        chap_index=$((i+1))
        chap_filename=$(printf "%02d_t%02d_z%02d_(%s).%s" "$chap_index" "$t_num" "$z_num" "$ch_label" "$ext")
        OUTFILE="${OUTDIR}/${chap_filename}"

        echo "  Chapter $chap_index: start=$START end=${END:-end-of-file}"
        echo "    -> $OUTFILE"

        if [[ -n "$END" ]]; then
            ffmpeg -nostdin -y -ss "$START" -to "$END" -i "$INPUT" -map 0:"$tid" -c:a "$ff_codec" "$OUTFILE" >/dev/null 2>&1
        else
            ffmpeg -nostdin -y -ss "$START" -i "$INPUT" -map 0:"$tid" -c:a "$ff_codec" "$OUTFILE" >/dev/null 2>&1
        fi
    done

    echo
done < "$TRACK_INFO_FILE"

rm -f "$CHAPTER_FILE" "$TRACK_INFO_FILE"

echo "Done."
