#!/bin/bash 

for mkv in *.mkv; do
  echo "=== $mkv ==="
  ./split_tracks.sh "$mkv"
  echo
done
