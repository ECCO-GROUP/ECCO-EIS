#!/bin/bash

# Recursively compares files between two directories. 
#
# Usage: ./misc_comp_dirs.sh [--with-md5] arg1 arg2
#
# arg1 and arg2 can be directories or inventory files created by
# misc_build_inventory.sh.  The script compares directory name, file
# name, and file size. The script also optionally compares the file's
# md5 hash (--with-md5); when using this md5 option and using
# inventory files as arg1 and/or arg2, the files created by
# misc_build_inventory.sh must have also been created with the md5
# option. Inventory files created by misc_build_inventory.sh with the
# md5 option can also be used by misc_comp_dirs.sh without comparing
# md5 hash.
#
# EMU provides an inventory for emu_input_dir
# (emu_userinterface_dir/misc_build_inventory.emu_input_dir.txt) with
# md5 hash as a reference. To compare contents of a user-downloaded
# emu_input_dir against this reference, run one of the following
# commands; 
#
# To compare name & size; 
# misc_comp_dirs.sh emu_input_dir emu_userinterface_dir/misc_build_inventory.emu_input_dir.txt
#
# To compare name, size, and md5 hash 
# misc_comp_dirs.sh --with-md5 emu_input_dir emu_userinterface_dir/misc_build_inventory.emu_input_dir.txt

set -e
set -u

with_md5=0

# Parse optional --with-md5
if [[ "$1" == "--with-md5" ]]; then
  with_md5=1
  shift
fi

arg1="$1"
arg2="$2"

# Output files
tmp1="compare_tmp1.txt"
tmp2="compare_tmp2.txt"
diffs="compare_diffs.txt"

# Helper to build or copy inventory
build_or_copy_inventory() {
  local source="$1"
  local target="$2"

  if [[ -d "$source" ]]; then
    echo "Building inventory for directory: $source"
    if [[ "$with_md5" -eq 1 ]]; then
      misc_build_inventory.sh --with-md5 "$source" "$target"
    else
      misc_build_inventory.sh "$source" "$target"
    fi

  elif [[ -f "$source" ]]; then
    echo "Using existing inventory file: $source"

    # Check the format of the first file entry
    local first_line
    first_line=$(grep -m1 '^F|' "$source" || true)

    if [[ -z "$first_line" ]]; then
      echo "Warning: No file entries found in $source. Skipping format verification."
      cp "$source" "$target"
    else
      local field_count
      field_count=$(awk -F'|' '{print NF}' <<< "$first_line")

      if [[ "$with_md5" -eq 1 && "$field_count" -ne 4 ]]; then
        echo "Error: Inventory $source does not include MD5 checksums, but --with-md5 was requested."
        exit 1
      fi

      if [[ "$with_md5" -eq 0 && "$field_count" -eq 4 ]]; then
        echo "Stripping MD5 checksums from inventory: $source"
        misc_strip_md5.sh "$source" > "$target"
      elif [[ "$with_md5" -eq 0 && ("$field_count" -eq 3 || "$field_count" -eq 4) ]]; then
        cp "$source" "$target"
      else
        echo "Error: Inventory $source has an unexpected format."
        exit 1
      fi
    fi

  else
    echo "Error: $source is neither a directory nor a file."
    exit 1
  fi
}

# Helper to normalize path (remove leading ./ if present)
normalize_path() {
  local path="$1"
  echo "${path#./}"
}

# Function to check if a path should be ignored by filename
should_ignore_path() {
  local path="$1"
  if [[ "$path" == *index.html* || "$path" == *.log* ]]; then
    return 0  # yes, should ignore
  else
    return 1  # no, do not ignore
  fi
}

# Build or copy inventories
build_or_copy_inventory "$arg1" "$tmp1"
build_or_copy_inventory "$arg2" "$tmp2"

# Normalize inventories (strip leading ./) to temporary normalized versions
tmp1_norm="compare_tmp1_norm.txt"
tmp2_norm="compare_tmp2_norm.txt"

awk -F'|' -v OFS='|' '{
  if (NF >= 3) {
    if ($3 ~ /^\.\//) {
      sub(/^\.\//, "", $3);
    }
  }
  print
}' "$tmp1" > "$tmp1_norm"

awk -F'|' -v OFS='|' '{
  if (NF >= 3) {
    if ($3 ~ /^\.\//) {
      sub(/^\.\//, "", $3);
    }
  }
  print
}' "$tmp2" > "$tmp2_norm"

# Compare
echo "Comparing inventories ..."
comm -3 <(sort "$tmp1_norm") <(sort "$tmp2_norm") > "$diffs"

# Exit immediately if there are no differences
if [[ ! -s "$diffs" ]]; then
  echo
  echo "No differences found."
  echo
  echo "=== Summary ==="
  echo "Inventory 1 saved in: $tmp1"
  echo "Inventory 2 saved in: $tmp2"
  echo "Differences saved in: $diffs"
  rm -f "$tmp1_norm" "$tmp2_norm"
  exit 0
fi

# Process differences
echo "Processing differences:"

# Set to track missing directories
declare -A missing_dirs

# First pass: record missing directories
while read -r line; do
  # Trim leading whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue

  # Detect field count
  field_count=$(awk -F'|' '{print NF}' <<< "$line")

  if [[ "$field_count" -eq 3 ]]; then
    IFS='|' read -r tag size path <<< "$line"
    hash=""
  elif [[ "$field_count" -eq 4 ]]; then
    IFS='|' read -r tag size hash path <<< "$line"
    if [[ "$with_md5" -eq 0 ]]; then
      hash=""
    fi
  else
    echo "Skipping malformed line: $line"
    continue
  fi

  path=$(normalize_path "$path")

  if [[ "$tag" == "D" ]]; then
    # Missing directory -- record it
    missing_dirs["$path"]=1
    echo "Directory missing: $path"
  fi
done < "$diffs"

# Second pass: process files
while read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue

  field_count=$(awk -F'|' '{print NF}' <<< "$line")

  if [[ "$field_count" -eq 3 ]]; then
    IFS='|' read -r tag size path <<< "$line"
    hash=""
  elif [[ "$field_count" -eq 4 ]]; then
    IFS='|' read -r tag size hash path <<< "$line"
    if [[ "$with_md5" -eq 0 ]]; then
      hash=""
    fi
  else
    continue
  fi

  path=$(normalize_path "$path")

  if [[ "$tag" == "F" ]]; then
    # First skip unwanted files based on name
    if should_ignore_path "$path"; then
      continue
    fi

    # Then skip if under a missing directory
    for missing_dir in "${!missing_dirs[@]}"; do
      if [[ "$path" == "$missing_dir/"* || "$path" == "$missing_dir"* ]]; then
        continue 2
      fi
    done

    size=${size:-0}
    if [[ -n "$hash" ]]; then
      echo "File differs or missing: $path (size: $size bytes, md5: $hash)"
    else
      echo "File differs or missing: $path (size: $size bytes)"
    fi
  fi
done < "$diffs"

echo
echo "=== Summary ==="
echo "Inventory 1 saved in: $tmp1"
echo "Inventory 2 saved in: $tmp2"
echo "Differences saved in: $diffs"

# Clean up temporary normalized files
rm -f "$tmp1_norm" "$tmp2_norm"
