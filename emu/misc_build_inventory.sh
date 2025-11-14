#!/bin/bash

# Usage:
#   ./misc_build_inventory.sh [--with-md5] [--nproc N] sourcedir outfile
# - --with-md5 : Include MD5 checksums
# - --nproc N  : Manually set number of parallel processes (used_nproc)
#                Otherwise defaults to 1/4 of available processors. 
#
# Recursively builds an inventory of files and directories under
# 'sourcedir' into 'outfile' Optionally includes MD5 checksum for
# files. Use 'outfile' with misc_comp_dirs.sh.

set -e
set -u

# Defaults
with_md5=0
manual_nproc=0

# Save where script was launched
launch_dir="$(pwd)"

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-md5)
      with_md5=1
      shift
      ;;
    --nproc)
      manual_nproc="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# Positional arguments
sourcedir="$1"
outfile="$2"

if [[ -z "$sourcedir" || -z "$outfile" ]]; then
  echo "Usage: $0 [--with-md5] [--nproc N] sourcedir outfile"
  exit 1
fi

if [[ ! -d "$sourcedir" ]]; then
  echo "Error: $sourcedir is not a directory."
  exit 1
fi

# Ensure outfile is an absolute path
if [[ "$outfile" != /* ]]; then
  outfile="$launch_dir/$outfile"
fi

# Determine number of parallel processes
if [[ "$manual_nproc" -gt 0 ]]; then
  used_nproc="$manual_nproc"
else
  cores=$(nproc)
  used_nproc=$(( (cores + 3) / 4 ))
  used_nproc=$(( used_nproc > 0 ? used_nproc : 1 ))
fi

# Temporary output file
tmp_output="$(mktemp /tmp/build_inventory_tmp.XXXXXX)"

echo "Building inventory for $sourcedir into $outfile using $used_nproc parallel processes ..."

(
  cd "$sourcedir"

  find . -type f > /tmp/files.list || { echo "Warning: No files found."; touch /tmp/files.list; }

  if [[ "$with_md5" -eq 0 ]]; then
    # Size only (parallelized)
    cat /tmp/files.list | xargs -n 1 -P "$used_nproc" bash -c '
      file="$1"
      printf "F|%s|%s\n" "$(stat -c %s "$file")" "$file"
    ' _ 
  else
    # Size + MD5 (parallelized)
    cat /tmp/files.list | xargs -n 1 -P "$used_nproc" bash -c '
      file="$1"
      printf "F|%s|%s|%s\n" "$(stat -c %s "$file")" "$(md5sum "$file" | cut -d" " -f1)" "$file"
    ' _
  fi

  # Now handle directories (sequential, very fast)
  find . -type d | while read -r dir; do
    if [[ "$with_md5" -eq 0 ]]; then
      echo "D||$dir"
    else
      echo "D|||$dir"
    fi
  done
) > "$tmp_output"

# Now sort outside and write to final outfile
sort "$tmp_output" > "$outfile"
rm -f "$tmp_output" /tmp/files.list

echo "Inventory written to $outfile"
