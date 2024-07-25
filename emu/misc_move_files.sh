#!/bin/bash -e 

umask 022

#=================================
# Script to move files including their target if symbolic link
#=================================

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source_directory> <destination_directory> <file_pattern>"
    exit 1
fi

# Source and destination directories and file pattern
src_dir=$(realpath "$1")
dest_dir=$(realpath "$2")
file_pattern="$3"

return_dir=$PWD

# Ensure destination directory exists
mkdir -p "$dest_dir"

# Find all files matching the pattern in the source directory
cd $src_dir
for file in ./$file_pattern; do
  # Check if the file exists to handle case where no files match the pattern
  [ -e "$file" ] || continue

  # Check if the file is a symbolic link
  if [ -L "$file" ]; then
    # Resolve the target of the symbolic link
    target_path=$(readlink "$file")

    # Copy the target file to the destination directory
    cp -f "$target_path" "$dest_dir/"

    # Get the base name of the target file
    target_file_name=$(basename "$target_path")

    # Move the symbolic link to the destination directory
    mv -f "$file" "$dest_dir/"

    # Update the symbolic link to point to the new location of the target file
    cd $dest_dir
    ln -sf ./"$target_file_name" ./"$(basename "$file")"
    cd $src_dir
  else
    # If it's not a symbolic link, simply move the file
    mv -f "$file" "$dest_dir/"
  fi
done
