#!/bin/bash -e 

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
# EMU useraccess directory

emu_userinterface_dir=PUBLICDIR

currentdir=$PWD
cd ${emu_userinterface_dir}

# ---------------------------------------
# 0) Rename all download.log files, if any, recursively. 
#    This saves logs from previous download attemps by emu_input_install.sh. 
#    Will search for ERROR messages later, if any, only in new log files.

find . -type f -name 'download.log' | while read -r file; do
    # Use stat to get the last modification time in YYYYMMDD_HHMM format
    timestamp=$(stat -c '%y' "$file" | awk '{print $1"_"$2}' | sed 's/[:-]//g' | cut -c1-13)

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
    read -p "Enter your WebDAV password: " WebDAV_password


    # Disable exit on error
    set +e

    # Check credentials using wget --spider
    OUTPUT=$(wget --spider --user="$Earthdata_username" --password="$WebDAV_password" "$URL" 2>&1)

    # Enable exit on error
    set -e 

    # Check the exit status of wget
    if echo "$OUTPUT" | grep -Ei "Remote file exists and could contain further links" > /dev/null 2>&1; then
#        echo "Earthdata/WebDAV Credentials confirmed"
        break
    else
	echo
        echo "Invalid username and/or password. Try again."
    fi
done

# ---------------------------------------
# 2) Select directory for EMU
#    Input files will be placed in subdirectories. 

emu_input_dir=EMU_INPUT_DIR

# 
echo
echo "----------------------"
echo "EMU input files will be placed in ... "
echo $emu_input_dir

# ---------------------------------------
# 3) Select what to download 

echo
echo "----------------------"
echo "Choosing what EMU input to download ... "
echo 
echo "EMU's Input Files total 1.1 TB, of which (directory)"
echo "   175 GB (emu_ref) is needed by Sampling, Forward Gradient, Adjoint, Tracer, Budget, and Attribution"
echo "   195 GB (forcing) is needed by Forward Gradient, Adjoint, Modified Simultion"
echo "   380 GB (state_weekly) is needed by Tracer"
echo "   290 GB (emu_msim) is needed by Attribution" 
echo "   (Convolution Tool uses results of the Adjoint Tool and files downloaded by default.)"
echo 
echo "Choose among the following to download ... "
echo "   0) All Input Files (1.1 TB) "
echo "   1) Files (~175 GB) needed for Sampling and Budget Tools"
echo "   2) Files (~195 GB) needed for Modified Simultion Tools" 
echo "   3) Files (~370 GB) needed for Adjoint and Forward Gradient Tool"
echo "   4) Files (~465 GB) needed for Attribution Tool" 
echo "   5) Files (~555 GB) needed for Tracer Tool"
echo ""
echo "Enter choice ... (0-5)?"
read emu_input 

while [[ ${emu_input} -lt 0 || ${emu_input} -gt 5 ]] ; do 
    echo 
    echo "Choice must be 0-5."
    read emu_input
done

echo
echo "Choice is "$emu_input
if [[ ! $emu_input -eq 0 ]]; then
    echo
    echo "Rerun this script $0 to download additional EMU input, if necessary."
fi

# ---------------------------------------
# Log the run
echo "**************************************" >> "${emu_input_dir}/download.log"
date >> "${emu_input_dir}/download.log"
echo "Running emu_input_install.sh with choice ${emu_input} " >> "${emu_input_dir}/download.log"

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
    mkdir ${forcing_dir}
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


# emu_ref
if [[ $emu_input -eq 0 || $emu_input -eq 1 || $emu_input -eq 3  || $emu_input -eq 4 || $emu_input -eq 5 ]]; then
    
    goto_download_indiv ${emu_input_dir} "emu_ref" 7 "other/flux-forced/emu_input/emu_ref/" &
    
fi

# forcing 
if [[ $emu_input -eq 0 || $emu_input -eq 2 || $emu_input -eq 3 ]]; then
    
    goto_download_indiv "${forcing_dir}/other/flux-forced" "forcing" 6 "other/flux-forced/forcing/" &
    
fi

# emu_msim
if [[ $emu_input -eq 0 || $emu_input -eq 4 ]]; then

    # Exclude diags directory 
    goto_download_indiv ${emu_input_dir} "emu_msim" 7 "other/flux-forced/emu_input/emu_msim/" "diags" &

    # Download diags directory
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
	local_path="emu_msim/${mean}/diags"
	remote_path="other/flux-forced/emu_input/emu_msim/${mean}/diags/"
	
	goto_download_indiv ${emu_input_dir} "$local_path" 7 "$remote_path" &
	pids_diags+=($!)  # store the PID of just this background job
    done

    # Wait only for these specific jobs
    for pid in "${pids_diags[@]}"; do
	wait "$pid"
    done
    
fi

# state_weekly
if [[ $emu_input -eq 0 || $emu_input -eq 5 ]]; then
    
    goto_download_indiv "${forcing_dir}/other/flux-forced" "state_weekly" 6 "other/flux-forced/state_weekly/" &
    pid_state_weekly_1=$!
    
    # Create circulation fields for adjoint tracer 
    
    goto_download_indiv "${emu_input_dir}" "scripts" 8 "other/flux-forced/emu_input/emu_misc/scripts/" &
    pid_state_weekly_2=$!

    wait $pid_state_weekly_1 $pid_state_weekly_2
    
    adstateweeklydir=${forcing_dir}/other/flux-forced/state_weekly_rev_time_227808
    if [ ! -d "${adstateweeklydir}" ]; then 
	echo
	echo "Generating adjoint tracer input by reverseintime_all.sh"
	tempdir=$PWD
	cd ${forcing_dir}/other/flux-forced
	ln -sf ${emu_input_dir}/scripts/* .
	bash -xv ./reverseintime_all.sh
	cd $tempdir
    fi
fi

# ---------------------------------------
# 5) End

wait

# Record the end time
end_time=$(date +%s)

# Calculate the difference from start_time
elapsed_time=$((end_time - start_time))

hours=$((elapsed_time / 3600))
minutes=$(((elapsed_time % 3600) / 60))
seconds=$((elapsed_time % 60))

# ---------------------------------------
# Log the run
echo " " >> "${emu_input_dir}/download.log"
date >> "${emu_input_dir}/download.log"
echo "End running emu_input_install.sh with choice ${emu_input} " >> "${emu_input_dir}/download.log"
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds >> "${emu_input_dir}/download.log"
echo "**************************************" >> "${emu_input_dir}/download.log"
echo " " >> "${emu_input_dir}/download.log"

# ---------------------------------------
# Check for ERRORs 

echo " " 
echo "----------------------"
echo " "

error_found=false

# Save the list of download.log files to a variable to avoid subshell
log_files=$(find . -type f -name 'download.log')

for logfile in $log_files; do
    awk -v logfile="$logfile" '
    {
        prev = curr
        curr = $0
        if (curr ~ /ERROR 502: Proxy Error/) {
            print "***** WARNING: 502 Proxy Error detected"
            print "Log file     : " logfile
            print "Problem line : " prev
            print "Error message: " curr
            print ""
            error = 1
        }
    }
    END {
        if (error) {
            exit 1
        }
    }' "$logfile"

    if [[ $? -eq 1 ]]; then
        error_found=true
    fi
done

# Print final outcome
if $error_found; then
    echo "***********************"    
    echo " Error(s) above encountered while downloading EMU input files." 
    echo " Rerun emu_input_setup.sh to download missing files."
    echo "***********************"        
else
    echo "Successfully set up EMU input by emu_input_install.sh"
fi

echo " "
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
echo "emu_input_install.sh execution complete. $(date)"

echo 
cd ${currentdir}

