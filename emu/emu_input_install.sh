#!/bin/bash

umask 022

#=================================
# Download input files needed by EMU
#=================================

echo " "
echo "Downloading EMU input files from ECCO Drive at NASA Earthdata ... "
echo " "
echo "-------------------------------------------------------------------------------------------------------"
echo "Users will need to obtain a NASA Earthdata account at https://ecco.jpl.nasa.gov/drive/"
echo "Use the Username and WebDAV password (not Earthdata password) below to proceed." 
echo "After obtaining an Earthdata account WebDAV password can be found at https://ecco.jpl.nasa.gov/drive/"
echo " "
echo "This program (emu_input_install.sh) can be run again in case of incomplete downloads or downloading "
echo "new files from ECCO Drive. "
echo "-------------------------------------------------------------------------------------------------------"

# ----------------------------------------
# Check wget availability
command -v wget >/dev/null || { echo "ERROR: wget not found"; exit 1; }

# ----------------------------------------
# EMU directories

emu_userinterface_dir=PUBLICDIR
emu_input_dir=EMU_INPUT_DIR

currentdir=$PWD
if ! cd "${emu_input_dir}"; then
    echo "ERROR: emu_input_dir '${emu_input_dir}' does not exist." >&2
    exit 1
fi

# Save original PATH
old_PATH=$PATH

# Add directory if missing
if [[ ":$PATH:" != *":$emu_userinterface_dir:"* ]]; then
    export PATH="$emu_userinterface_dir:$PATH"
    trap 'export PATH=$old_PATH' EXIT
    echo "Temporarily added $emu_userinterface_dir to PATH"
fi

# ---------------------------------------
# 0) Rename all download.log files, if any, recursively. 
#    This saves logs from previous download attemps by emu_input_install.sh. 
#    Will search for ERROR messages later, if any, only in new log files.

ts() {
  if stat --version >/dev/null 2>&1; then
    stat -c '%y' "$1" | awk '{print $1"_"$2}' | sed 's/[:-]//g' | cut -c1-13
  else
    # macOS/BSD
    # %Sm with -t outputs like YYYYMMDD_HHMM
    stat -f '%Sm' -t '%Y%m%d_%H%M' "$1"
  fi
}

find . -type f -name 'download.log' | while read -r file; do
    # Use stat to get the last modification time in YYYYMMDD_HHMM format
    timestamp=$(ts "$file")

    # Construct new file name
    new_file="${file}_${timestamp}"

    # Rename the file
    mv "$file" "$new_file"
    echo "Renamed: $file -> $new_file"
done

# ---------------------------------------
# 1) Enter Earthdata username & password

echo
echo "----------------------"
echo "Reading Earthdata credentials" 
URL="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced"

while true; do
    # Prompt for username
    echo
    read -p "Enter your Earthdata username: " Earthdata_username

    # Prompt for password
    read -p "Enter your WebDAV password (*NOT* Earthdata password): " WebDAV_password
    echo

    # Check credentials using wget --spider
    OUTPUT=$(wget --spider --user="$Earthdata_username" --password="$WebDAV_password" "$URL" 2>&1)

    # Check the exit status of wget
    if echo "$OUTPUT" | grep -Ei "Remote file exists and could contain further links" > /dev/null 2>&1; then
#        echo "Earthdata/WebDAV Credentials confirmed"
        break
    else
	if echo "$OUTPUT" | grep -Ei "Username/Password Authentication Failed|Authorization failed" > /dev/null; then
            echo "Invalid username and/or password. Try again."
            echo
	else
	    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "ERROR: wget to Earthdata $URL. "
	    echo "       Issue may be with server or client." 
            echo "       wget returns the following:" 
	    echo 
            echo "$OUTPUT"
	    echo 
	    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
	    echo 
            exit 1
	fi
    fi
done

# ---------------------------------------
# 2) Select directory for EMU
#    Input files will be placed in subdirectories under $emu_input_dir

echo
echo "----------------------"
echo "EMU input files will be placed in ... "
echo "${emu_input_dir}"

# ---------------------------------------
# 3) Select what to download 

echo
echo "----------------------"
echo "Choosing what EMU input to download ... "
echo 
echo "EMU's Input Files total 1.1 TB, of which (directory)"
echo "   ~175 GB (emu_ref) is needed by Sampling, Forward Gradient, Adjoint, Tracer, Budget, and Attribution"
echo "   ~195 GB (forcing) is needed by Forward Gradient, Adjoint, Modified Simulation"
echo "   ~380 GB (state_weekly) is needed by Tracer"
echo "   ~290 GB (emu_msim) is needed by Attribution" 
echo "   (Convolution Tool uses results of the Adjoint Tool and files downloaded by default.)"
echo 
echo "Choose among the following to download ... "
echo "   0) All Input Files (1.1 TB) "
echo "   1) Files (~175 GB) needed for Sampling and Budget Tools"
echo "   2) Files (~195 GB) needed for Modified Simulation Tools" 
echo "   3) Files (~370 GB) needed for Adjoint and Forward Gradient Tool"
echo "   4) Files (~465 GB) needed for Attribution Tool" 
echo "   5) Files (~555 GB) needed for Tracer Tool"
echo ""
echo "Enter choice ... (0-5)?"
read emu_input 

while ! [[ $emu_input =~ ^[0-5]$ ]]; do
    echo 
    echo "Choice must be 0-5."
    read emu_input
done

echo
echo "Choice is $emu_input"
if [[ ! $emu_input -eq 0 ]]; then
    echo
    echo "Rerun this script $0 to download additional EMU input, if necessary."
fi

# ---------------------------------------
# Option to skip checking integrity of what's downloaded at the end. 
echo 
echo "Press ENTER key to check integrity of downloaded files (by misc_check_input.sh) "
echo "or enter NO to skip this step ... ?"
read emu_check_input
if [[ "${emu_check_input,,}" == "no" ]]; then
    emu_check_input=n
    echo 
    echo "Skipping integrity check." 
    echo "Integrity of files downloaded in "
    echo "$emu_input_dir"
    echo "can be checked later by misc_check_input.sh. " 
else
    emu_check_input=y
    echo 
    echo "Will conduct integrity check at the end of this script by misc_check_input.sh." 
fi

# ---------------------------------------
# Log the run
master_log=${emu_input_dir}/download.log
echo "**************************************" >> "${master_log}"
date >> "${master_log}"
echo "Running emu_input_install.sh with choice ${emu_input} " >> "${master_log}"
echo "Checking integrity of download by misc_check_input.sh ... ${emu_check_input} " >> "${master_log}"

# ---------------------------------------
# Code to Download individual directories
goto_download_indiv() {
    local target_dir="$1/$2"
    local base_dir="$1"
    local cut_dirs="$3"
    local remote_path="$4"
    local exclude_dir="$5"
    local exclude_opt=""
    if [[ -n "$exclude_dir" ]]; then
	exclude_opt="--reject-regex=/$exclude_dir/"
    fi
    local log_file="${base_dir}/download.log"

    echo
    echo "Checking and updating directory: $target_dir"
    mkdir -p "$target_dir"

    local before_files=$(find "$target_dir" -type f | wc -l)
    local before_size=$(du -sb "$target_dir" | cut -f1)

    # Perform download and append to log
    wget -r -np -nH -N -c \
        --no-verbose \
	--reject "index.html*" \
	--retry-connrefused --tries=10 --waitretry=5 \
	$exclude_opt \
        -P "$base_dir" \
        --cut-dirs="$cut_dirs" \
        --user "$Earthdata_username" \
        --password "$WebDAV_password" \
        "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/$remote_path" \
        -a "$log_file"

    local after_files=$(find "$target_dir" -type f | wc -l)
    local after_size=$(du -sb "$target_dir" | cut -f1)

    if [[ $after_files -eq $before_files && $after_size -eq $before_size ]]; then
        echo "Directory is already up to date: $target_dir"
        echo "$(date): Up-to-date: $target_dir" >> "$log_file"
    else
        echo "Downloaded or updated $((after_files - before_files)) file(s), total size now $after_size bytes: $target_dir"
        echo "$(date): Updated $target_dir ($((after_files - before_files)) new files)" >> "$log_file"
    fi
}

#goto_download_indiv() {
#    dum=$1/$2
#    if [[ ! -d "${dum}" ]]; then
## input_init
#	wget -P $1 -r --no-parent --user $Earthdata_username \
#	    --password $WebDAV_password -nH \
#	    --cut-dirs=$3 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/$4
#    else
#	echo
#	echo "Directory already exists: " $dum
#	echo "Skipping downloading " $2
#    fi
#}

# ---------------------------------------
# 4) Download Chosen EMU input 

echo
echo "----------------------"
echo "Downloading EMU input interactively ... "

# Record the start time
start_time=$(date +%s)

# Create forcing directory if not present 
forcing_dir=${emu_input_dir}/forcing
if [[ ! -d "${forcing_dir}" ]]; then
    mkdir "${forcing_dir}"
fi

# Download small input 

# input_init
goto_download_indiv ${forcing_dir} "input_init" 4 "input_init/" &

# forcing_weekly
goto_download_indiv ${forcing_dir} "other/flux-forced/forcing_weekly" 4 "other/flux-forced/forcing_weekly/" &

# mask
goto_download_indiv ${forcing_dir} "other/flux-forced/mask" 4 "other/flux-forced/mask/" &

# xx
goto_download_indiv ${forcing_dir} "other/flux-forced/xx" 4 "other/flux-forced/xx/" &

# EMU's additional input_init (Files reflecting folding initial condition & parameter controls to reference)
goto_download_indiv ${forcing_dir} "other/flux-forced/input_init" 4 "other/flux-forced/input_init/" &

# emu_ref
if [[ $emu_input -eq 0 || $emu_input -eq 1 || $emu_input -eq 3  || $emu_input -eq 4 || $emu_input -eq 5 ]]; then
    
    goto_download_indiv ${emu_input_dir} "emu_ref" 7 "other/flux-forced/emu_input/emu_ref/" &
    
fi

wait || true

# forcing 
if [[ $emu_input -eq 0 || $emu_input -eq 2 || $emu_input -eq 3 ]]; then
    
    goto_download_indiv "${forcing_dir}/other/flux-forced" "forcing" 6 "other/flux-forced/forcing/" &
    
fi

wait || true

# emu_atrb
if [[ $emu_input -eq 0 || $emu_input -eq 4 ]]; then

    # Download each separate msim result directory
    means=(
	mean_ALL
	mean_IC
	mean_oceFWflx
	mean_oceSflux_oceSPflx
	mean_oceTAUX_oceTAUY
	mean_sIceLoadPatmPload_nopabar
	mean_TFLUX_oceQsw
    )

    # Store PIDs of background jobs
    pids_diags=()

    # Launch diags downloads in background
    for mean in "${means[@]}"; do
	local_path="emu_msim/${mean}"
	remote_path="other/flux-forced/emu_input/emu_msim/${mean}/"
	
	goto_download_indiv ${emu_input_dir} "$local_path" 7 "$remote_path" &
	pids_diags+=($!)  # store the PID of just this background job
    done

    # Wait only for these specific jobs
    for pid in "${pids_diags[@]}"; do
	wait "$pid" || true 
    done
    
fi

# state_weekly
if [[ $emu_input -eq 0 || $emu_input -eq 5 ]]; then
    
    goto_download_indiv "${forcing_dir}/other/flux-forced" "state_weekly" 6 "other/flux-forced/state_weekly/" &
    pid_state_weekly_1=$!
    
    # Create circulation fields for adjoint tracer 
    
    goto_download_indiv "${emu_input_dir}" "scripts" 8 "other/flux-forced/emu_input/emu_misc/scripts/" &
    pid_state_weekly_2=$!

    wait $pid_state_weekly_1 $pid_state_weekly_2 || true
    
    adstateweeklydir=${forcing_dir}/other/flux-forced/state_weekly_rev_time_227808
    if [ ! -d "${adstateweeklydir}" ]; then 
	echo
	echo "Generating adjoint tracer input by reverseintime_all.sh"
	tempdir=$PWD
	cd "${forcing_dir}/other/flux-forced"
	ln -sf ${emu_input_dir}/scripts/* .
	bash ./reverseintime_all.sh
	cd "$tempdir"
    fi
fi

# ---------------------------------------
# 5) End Download

wait || true 

# Record the end time
end_time=$(date +%s)
# Calculate the difference from start_time
elapsed_time=$((end_time - start_time))

hours=$((elapsed_time / 3600))
minutes=$(((elapsed_time % 3600) / 60))
seconds=$((elapsed_time % 60))

# ---------------------------------------
# Log the run
echo " " >> "${master_log}"
date >> "${master_log}"
echo "End downloading files with choice ${emu_input} " >> "${master_log}"
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds >> "${master_log}"
echo "**************************************" >> "${master_log}"

# ---------------------------------------
# Check for ERRORs 

echo " " 
echo "----------------------"
echo " "

error_found=false

# Save the list of download.log files to a variable to avoid subshell
log_files=$(find . -type f -name 'download.log')

# Check for ERROR 502 messages in all download.log files
for logfile in $log_files; do
  awk -v logfile="$logfile" '
    {
      prev = curr
      curr = $0
      if (curr ~ /ERROR 502: Proxy Error/) {
        print "***** WARNING: 502 Proxy Error detected" > "/dev/tty"
        print "Log file     : " logfile  > "/dev/tty"
        print "Problem line : " prev     > "/dev/tty"
        print "Error message: " curr     > "/dev/tty"
        print ""                        > "/dev/tty"
        error = 1
      }
    }
    END { if (error) exit 1 }
  ' "$logfile" || error_found=true
done

# Print outcome of checking download.log files 
if $error_found; then
    echo  > /dev/tty 
    echo "***********************"    > /dev/tty 
    echo " Error(s) above encountered while downloading EMU input files"   > /dev/tty 
    echo " possibly due to server overload."   > /dev/tty 
    echo " Rerun emu_input_install.sh to download any missing files."  > /dev/tty 
    echo "***********************"    > /dev/tty         
#else
#    echo "Successfully set up EMU input by emu_input_install.sh"
fi

# ---------------------------------------
# Check integrity of download
if [[ "$emu_check_input" =~ [yY] ]]; then
    echo " " > /dev/tty
    echo "**************************************"  > /dev/tty
    echo "Checking integrity of EMU input download "  > /dev/tty

    echo " " >> "${master_log}"
    echo "**************************************" >> "${master_log}"
    echo "Checking integrity of EMU input download "  >> "${master_log}"

    local_inventory=misc_build_inventory.local.txt 

    echo   > /dev/tty
    echo " Checking integrity of ${emu_input_dir} ... "  > /dev/tty
    echo " First creating inventory by misc_build_inventory.sh ... " > /dev/tty

    echo  >> "${master_log}"
    echo " Checking integrity of ${emu_input_dir} ... "  >> "${master_log}"
    echo " First creating inventory by misc_build_inventory.sh ... " >> "${master_log}"

    misc_build_inventory.sh --with-md5 ${emu_input_dir} ${local_inventory}  >> "${master_log}" 2>> "${master_log}" 

    echo  > /dev/tty
    echo " Next checking inventory against reference by misc_check_input.sh ... "  > /dev/tty

    echo   >> "${master_log}"
    echo " Next checking inventory against reference by misc_check_input.sh ... "  >> "${master_log}"

    misc_check_input.sh --with-md5 <<EOF >> "${master_log}" 2>> "${master_log}" 
${local_inventory}
${emu_input}
EOF
    master_missing="misc_check_input.missing.inv"
    missing_count=$(grep -c . "$master_missing" || true)
    if [[ "$missing_count" -eq 0 ]]; then
	echo  > /dev/tty
	echo "All expected files and directories are present in "  > /dev/tty
	echo "${emu_input_dir}"  > /dev/tty

	echo  >> "${master_log}"
	echo "All expected files and directories are present in "  >> "${master_log}"
	echo "${emu_input_dir}"  >> "${master_log}"
    else
	echo
	echo " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! "  > /dev/tty
	echo " Files and/or directories are missing ... "   > /dev/tty
   	echo "    Number of missing files/directories: $missing_count"  > /dev/tty
	echo "    Missing files/directories identified in: $master_missing"  > /dev/tty
	echo " Run emu_input_install.sh to download missing files/directories."  > /dev/tty
	echo " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! "

	echo  >> "${master_log}"
	echo " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! "  >> "${master_log}"
	echo " Files and/or directories are missing ... "   >> "${master_log}"
   	echo "    Number of missing files/directories: $missing_count"  >> "${master_log}"
	echo "    Missing files/directories identified in: $master_missing"  >> "${master_log}"
	echo " Run emu_input_install.sh to download missing files/directories."   >> "${master_log}"
	echo " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! "  >> "${master_log}"
    fi

    # Record the end time of integrity check 
    end_time_check=$(date +%s)

    # Calculate the difference from end of download 
    elapsed_time_check=$((end_time_check - end_time))

    hours_check=$((elapsed_time_check / 3600))
    minutes_check=$(((elapsed_time_check % 3600) / 60))
    seconds_check=$((elapsed_time_check % 60))

    echo " " >> "${master_log}"
    echo "End integrity checking files " >> "${master_log}"
    printf "Elapsed time: %d:%02d:%02d\n" $hours_check $minutes_check $seconds_check >> "${master_log}"
    echo "**************************************" >> "${master_log}"
fi

# ----------------------------------------
# Wrap up

# Record the end time
end_time=$(date +%s)
end_date=$(date)
# Calculate the difference from start_time
elapsed_time=$((end_time - start_time))

hours=$((elapsed_time / 3600))
minutes=$(((elapsed_time % 3600) / 60))
seconds=$((elapsed_time % 60))

echo " "
printf "Total Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
echo "emu_input_install.sh execution complete. ${end_date}"

echo " "  >> "${master_log}"
printf "Total Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds  >> "${master_log}"
echo "emu_input_install.sh execution complete. ${end_date}"  >> "${master_log}"

echo 
cd "${currentdir}"

