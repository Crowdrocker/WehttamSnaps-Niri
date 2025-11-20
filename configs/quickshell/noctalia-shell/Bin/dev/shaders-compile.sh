#!/bin/bash

# Directory containing the source shaders.
SOURCE_DIR="Shaders/frag/"

# Directory where the compiled shaders will be saved.
DEST_DIR="Shaders/qsb/"

# Check if the source directory exists.
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory $SOURCE_DIR not found!"
    exit 1
fi

# Create the destination directory if it doesn't exist.
mkdir -p "$DEST_DIR"

# Loop through all files in the source directory ending with .frag
for shader in "$SOURCE_DIR"*.frag; do
    # Check if a file was found (to handle the case of no .frag files).
    if [ -f "$shader" ]; then
        # Get the base name of the file (e.g., wp_fade).
        shader_name=$(basename "$shader" .frag)

        # Construct the output path for the compiled shader.
        output_path="$DEST_DIR$shader_name.frag.qsb"

        # Construct and run the qsb command.
        qsb --qt6 -o "$output_path" "$shader"

        # Print a message to confirm compilation.
        echo "Compiled $shader to $output_path"
    fi
done

echo "Shader compilation complete."