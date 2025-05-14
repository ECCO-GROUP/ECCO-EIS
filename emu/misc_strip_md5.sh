#!/bin/bash
# Strip md5 hash field from misc_build_inventory.sh output
#
# Usage: ./misc_strip_md5.sh input_inventory.txt > output_inventory.txt

input="$1"

awk -F'|' '
# Directory line: change D|||path to D||path
$1 == "D" {
  print $1 "||" $4
  next
}

# File line with MD5 (4 fields): strip MD5
$1 == "F" && NF == 4 {
  print $1 "|" $2 "|" $4
  next
}

# File line without MD5 (3 fields): keep as-is
$1 == "F" && NF == 3 {
  print
  next
}

# Other lines: print as-is
{
  print
}
' "$input"
