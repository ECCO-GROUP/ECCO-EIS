#!/bin/bash

# misc_check_input.sh
#
# Compare EMU input downloaded by emu_input_install.sh (LOCAL) against
# a known-complete MASTER inventory (misc_build_inventory.emu_input_dir.txt). 
#
# This script:
#   - Prompts for your LOCAL EMU input (either the emu_input_dir DIRECTORY 
#     or its INVENTORY FILE created by misc_build_inventory.sh).
#   - Prompts which emu_input choice (0-5) of emu_input_install.sh to test against.
#   - Builds/validates the LOCAL inventory and scopes it ONLY to directories
#     that that emu_input choice downloads.
#   - Filters the MASTER inventory to the same scope.
#   - Produces:
#       misc_check_input.scoped_local.inv  (scoped local)
#       misc_check_input.scoped_master.inv  (scoped master)
#       misc_check_input.missing.inv (items present in master but missing locally)
#     and prints a count of missing items (files + directories).
#
# Usage:
#   misc_check_input.sh [--with-md5] [--nproc N]
#
# Requirements on PATH:
#   misc_build_inventory.sh   (builds inventories)
#   misc_strip_md5.sh         (optional; if absent we fall back to awk)
#
# Notes:
#   - Inventory format follows misc_build_inventory.sh:
#       F|size|path             or F|size|md5|path
#       D||path                 or D|||path
#   - When --with-md5 is requested, any provided inventory must include MD5.
#   - When --with-md5 is NOT requested but an inventory has MD5, we strip it.

set -euo pipefail

with_md5=0
manual_nproc=0

# ---------- Parse options ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-md5) with_md5=1; shift ;;
    --nproc)    manual_nproc="${2:-0}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--with-md5] [--nproc N]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Determine nproc to pass to misc_build_inventory.sh (optional)
nproc_args=()
if [[ "${manual_nproc}" -gt 0 ]]; then
  nproc_args=(--nproc "${manual_nproc}")
fi

# ---------- Prompt for inputs ----------
echo
read -rp "Enter path to your emu_input_dir (or an inventory file built by misc_build_inventory.sh): " emu_input_src
if [[ ! -e "$emu_input_src" ]]; then
  echo "Error: '$emu_input_src' does not exist." >&2
  exit 1
fi

echo
echo "Which emu_input choice of emu_input_install.sh to check against?"
echo "  0) All"
echo "  1) Sampling & Budget (needs emu_ref)"
echo "  2) Modified Simulation (needs forcing)"
echo "  3) Adjoint & Forward Gradient (needs emu_ref + forcing)"
echo "  4) Attribution (needs emu_ref + emu_msim)"
echo "  5) Tracer (needs emu_ref + state_weekly + scripts)"
read -rp "Enter choice (0-5): " emu_input
if [[ ! "$emu_input" =~ ^[0-5]$ ]]; then
  echo "Error: choice must be 0-5." >&2
  exit 1
fi

# ---------- Locate master inventory ----------
master_candidates=(
  "PUBLICDIR/misc_build_inventory.emu_input_dir.txt"
  "./misc_build_inventory.emu_input_dir.txt"
)
master_inv=""
for cand in "${master_candidates[@]}"; do
  if [[ -f "$cand" ]]; then
    master_inv="$cand"
    break
  fi
done
if [[ -z "$master_inv" ]]; then
  read -rp "Enter path to master inventory (misc_build_inventory.emu_input_dir.txt): " master_inv
  if [[ ! -f "$master_inv" ]]; then
    echo "Error: master inventory not found: $master_inv" >&2
    exit 1
  fi
fi

# ---------- Build list of prefixes corresponding to emu_input choice ----------
# Small input under ${emu_input_dir}/forcing always downloaded by installer
prefixes=(
  "forcing/input_init"
  "forcing/other/flux-forced/forcing_weekly"
  "forcing/other/flux-forced/mask"
  "forcing/other/flux-forced/xx"
  "forcing/other/flux-forced/input_init"
)

case "$emu_input" in
  0) prefixes+=(
        "emu_ref"
        "forcing/other/flux-forced/forcing"
        "emu_msim/mean_ALL"
        "emu_msim/mean_IC"
        "emu_msim/mean_oceFWflx"
        "emu_msim/mean_oceSflux_oceSPflx"
        "emu_msim/mean_oceTAUX_oceTAUY"
        "emu_msim/mean_sIceLoadPatmPload_nopabar"
        "emu_msim/mean_TFLUX_oceQsw"
        "forcing/other/flux-forced/state_weekly"
        "scripts"
      ) ;;
  1) prefixes+=("emu_ref") ;;
  2) prefixes+=("forcing/other/flux-forced/forcing") ;;
  3) prefixes+=("emu_ref" "forcing/other/flux-forced/forcing") ;;
  4) prefixes+=(
        "emu_ref"
        "emu_msim/mean_ALL"
        "emu_msim/mean_IC"
        "emu_msim/mean_oceFWflx"
        "emu_msim/mean_oceSflux_oceSPflx"
        "emu_msim/mean_oceTAUX_oceTAUY"
        "emu_msim/mean_sIceLoadPatmPload_nopabar"
        "emu_msim/mean_TFLUX_oceQsw"
      ) ;;
  5) prefixes+=(
        "emu_ref"
        "forcing/other/flux-forced/state_weekly"
        "scripts"
      ) ;;
esac

# ---------- Helpers ----------
normalize_path() {
  local p="$1"
  echo "${p#./}"
}

# Build/copy a LOCAL inventory from a directory or inventory file.
# Validates format similar to misc_comp_dirs.sh.
build_or_copy_local_inventory() {
  local src="$1"   # directory or inventory file
  local out="$2"   # inventory path to write

  if [[ -d "$src" ]]; then
    # Build from directory
    if [[ "$with_md5" -eq 1 ]]; then
      misc_build_inventory.sh --with-md5 ${nproc_args+"${nproc_args[@]}"} "$src" "$out"
    else
      misc_build_inventory.sh ${nproc_args+"${nproc_args[@]}"} "$src" "$out"
    fi
  elif [[ -f "$src" ]]; then
    # Validate inventory format
    echo "Using existing inventory file: $src"
    local first_file_line
    first_file_line=$(grep -m1 '^F|' "$src" || true)

    if [[ -z "$first_file_line" ]]; then
      echo "Warning: No file entries found in $src. Copying as-is."
      if [[ ! "$src" -ef "$out" ]]; then
	  tmpfile="$(mktemp /tmp/emu_inv.XXXXXX)"
	  cp "$src" "$tmpfile"
	  mv "$tmpfile" "$out"
      fi
      return
    fi

    local field_count
    field_count=$(awk -F'|' '{print NF}' <<< "$first_file_line")

    if [[ "$with_md5" -eq 1 && "$field_count" -ne 4 ]]; then
      echo "Error: Inventory $src does not include MD5 checksums, but --with-md5 was requested."
      exit 1
    fi

    if [[ "$with_md5" -eq 0 && "$field_count" -eq 4 ]]; then
      # Strip MD5 checksums
      if command -v misc_strip_md5.sh >/dev/null 2>&1; then
        misc_strip_md5.sh "$src" > "$out"
      else
        # Fallback: drop 3rd field on F-lines; collapse D-lines accordingly
        awk -F'|' -v OFS='|' '
          $1=="F" && NF==4 {print $1,$2,$4; next}
          $1=="D" && NF==4 {print $1,"",$4; next}
          {print}
        ' "$src" > "$out"
      fi
    elif [[ ( "$with_md5" -eq 0 && "$field_count" -eq 3 ) || \
            ( "$with_md5" -eq 1 && "$field_count" -eq 4 ) ]]; then
      if [[ ! "$src" -ef "$out" ]]; then
	  tmpfile="$(mktemp /tmp/emu_inv.XXXXXX)"
	  cp "$src" "$tmpfile"
	  mv "$tmpfile" "$out"
      fi
    else
      echo "Error: Inventory $src has an unexpected format."
      exit 1
    fi
  else
    echo "Error: $src is neither a directory nor a file."
    exit 1
  fi
}

# Filter a full inventory to only the chosen prefixes
filter_inventory_to_prefixes() {
  local inv="$1"; shift
  local -a prefs=( "$@" )

  # Join all prefixes into a single newline-separated string for awk.
  local prefs_blob=""
  if ((${#prefs[@]} > 0)); then
    prefs_blob="$(printf '%s\n' "${prefs[@]}")"
  fi

  awk -F'|' -v OFS='|' -v PREFS="$prefs_blob" '
    BEGIN {
      # Split newline-separated prefixes into array P[1..n]
      n = split(PREFS, P, /\n/)
    }

    # Strip leading "./" (including repeated "././") from a path
    function norm(p){ gsub(/^\.\/+/, "", p); return p }

    # Return 1 if path starts with any prefix in P[], else 0
    function keep(path,   i) {
      for (i = 1; i <= n; i++) {
        if (P[i] != "" && index(path, P[i]) == 1) return 1
      }
      return 0
    }

    {
      # Normalize the path field (4th if NF==4, else 3rd if NF==3)
      if (NF == 4) { $4 = norm($4); path = $4 }
      else if (NF == 3) { $3 = norm($3); path = $3 }
      else { path = "" }  # lines with other field counts will not match

      if (keep(path)) print
    }
  ' "$inv"
}

# ---------- Build LOCAL scoped inventory ----------
tmp_local_full="$(mktemp /tmp/emu_local_full.XXXXXX)"
build_or_copy_local_inventory "$emu_input_src" "$tmp_local_full"

tmp_local_scoped="$(mktemp /tmp/emu_local_scoped.XXXXXX)"
> "$tmp_local_scoped"

# Filter local inventory to prefixes
filter_inventory_to_prefixes "$tmp_local_full" "${prefixes[@]}" > "$tmp_local_scoped"

# ---------- Build MASTER scoped inventory ----------
tmp_master_scoped="$(mktemp /tmp/emu_master_scoped.XXXXXX)"
filter_inventory_to_prefixes "$master_inv" "${prefixes[@]}" > "$tmp_master_scoped"

# ---------- Finalize scoped inventories ----------
local_scoped="misc_check_input.scoped_local.inv"
master_scoped="misc_check_input.scoped_master.inv"

sort -o "$local_scoped"  "$tmp_local_scoped"
sort -o "$master_scoped" "$tmp_master_scoped"

# --- Harmonize field counts (strip MD5 when --with-md5 is NOT requested) ---
if [[ "$with_md5" -eq 0 ]]; then
  to3() {
    local in="$1" out="$2"
    awk -F'|' -v OFS='|' '
      $1=="F" && NF==4 { print $1, $2, $4; next }  # F|size|md5|path -> F|size|path
      $1=="D" && NF==4 { print $1, "",  $4; next }  # D|||path      -> D||path
      { print }                                     # already 3-field
    ' "$in" > "$out"
  }
  tmp_l="$(mktemp /tmp/emu_to3_l.XXXXXX)"
  tmp_m="$(mktemp /tmp/emu_to3_m.XXXXXX)"
  to3 "$local_scoped"  "$tmp_l" && mv "$tmp_l" "$local_scoped"
  to3 "$master_scoped" "$tmp_m" && mv "$tmp_m" "$master_scoped"
fi

# ---------- Master-only (missing locally) list & count ----------
master_missing="misc_check_input.missing.inv"

comm -13 <(sort "$local_scoped") <(sort "$master_scoped") > "$master_missing"

missing_count=$(grep -c . "$master_missing" || true)

echo > /dev/tty
echo "Master-only items (missing from your download) saved in: $master_missing"  > /dev/tty
echo > /dev/tty
echo "************************************************************************"  > /dev/tty
if [[ "$missing_count" -eq 0 ]]; then
  echo "All expected files and directories are present."  > /dev/tty
else
  echo "Number of missing files/directories: $missing_count"  > /dev/tty
fi
echo "************************************************************************"  > /dev/tty
echo  > /dev/tty

# ---------- Done ----------
echo
echo "=== Summary ==="
echo "Local (scoped) inventory   : $local_scoped"
echo "Master (scoped) inventory  : $master_scoped"
echo "Master-only (missing local): $master_missing"

