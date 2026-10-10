#!/bin/bash

# Define directories
SRC_DIR="$HOME/.config/snapsos/fastfetch/src"
OUT_DIR="$HOME/.config/snapsos/fastfetch/gen"

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Loop over all image files in the source directory
for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp}; do
    # Skip if no files match the pattern
    [ -e "$img" ] || continue

    # Extract filename without extension
    filename=$(basename -- "$img")
    filename_noext="${filename%.*}"

    # Output file path
    out_file="$OUT_DIR/$filename_noext"

    # Convert image to ASCII art using jp2a
    jp2a --height=22 --colors --background=dark "$img" > "$out_file"

    # Print status
    echo "Converted $img to $out_file"
done

echo "Conversion complete. ASCII art files are in $OUT_DIR"
