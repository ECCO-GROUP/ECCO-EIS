#!/bin/bash -e 

umask 022

#=================================
# Download input files needed by EMU
#
# Simplified version of emu_download_input.sh for pbs_emu_download_input.sh. 
# This has the same input in the same order but does not do batch. 
# This also moves the Earthdata credentials check to after all terminal input 
# is read, in case wget disrupts the heredoc. (At NAS, wget must be done
# on login nodes via ssh which disrupts the heredoc.) 
#=================================

echo " "
echo "Downloading EMU input files from ECCO Drive at NASA Earthdata ... "
echo " "
echo "-------------------------------------------------------------------------------------------------------"
echo "Users will need to obtain a NASA Earthdata account at https://ecco.jpl.nasa.gov/drive/"
echo "Use the Username and WebDAV password (not Earthdata password) below to proceed." 
echo "After obtaining an Earthdata account WebDAV password can be found at https://ecco.jpl.nasa.gov/drive/"
echo "-------------------------------------------------------------------------------------------------------"

# ----------------------------------------
# ID path to EMU useraccess files 

# Get the full path of this script
script_path=$(readlink -f "$0")

# Get the directory containing the script
useraccessdir=$(dirname "$script_path")

currentdir=$PWD
cd ${useraccessdir}

# ---------------------------------------
# 1) Enter Earthdata username & password

    # Prompt for username
    echo
    echo "Enter your Earthdata username: " 
    read Earthdata_username

    # Prompt for password
    echo
    echo "Enter your WebDAV password: " 
    read WebDAV_password

# ---------------------------------------
# 2) Select directory for EMU
#    Input files will be placed in subdirectories. 
echo " "
echo "Enter directory name to place EMU Input (emu_input_dir) ... ?"
read emu_input_dir

# Convert emu_input_dir to absolute pathname 
emu_input_dir=$(readlink -f "$emu_input_dir")

echo " "
echo "EMU input files will be placed in ... "
echo $emu_input_dir

# ---------------------------------------
# 3) Select what to download 

echo
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
read emu_choice 

echo 
echo "Choice is "$emu_choice

if [[ ${emu_choice} -lt 0 || ${emu_choice} -gt 5 ]]; then
    echo
    echo "Choice must be one of 0-5."
    exit 
fi

# ---------------------------------------
# Code to Download individual directories
goto_download_indiv() {
    dum=$1/$2
    if [[ ! -d "${dum}" ]]; then
# input_init
	wget -P $1 -r --no-parent --user $Earthdata_username \
	    --password $WebDAV_password -nH \
	    --cut-dirs=$3 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/$4
    else
	echo
	echo "Directory already exists: " $dum
	echo "Skipping downloading " $2
    fi
}

# ---------------------------------------
# 4) Download Chosen EMU input 

# Check Earthdata credentials
URL="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced"
    # Disable exit on error
    set +e

    # Check credentials using wget --spider
    OUTPUT=$(wget --spider --user="$Earthdata_username" --password="$WebDAV_password" "$URL" 2>&1)

    # Enable exit on error
    set -e 

    # Check the exit status of wget
    if ! echo "$OUTPUT" | grep -Ei "Remote file exists and could contain further links" > /dev/null 2>&1; then
	echo 
        echo "Invalid Earthdata username and/or WebDAV password."
	exit 
    fi

# Begin download
    echo
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
    goto_download_indiv ${forcing_dir} "input_init" 4 "input_init"

    # forcing_weekly
    goto_download_indiv ${forcing_dir} "forcing_weekly" 4 "other/flux-forced/forcing_weekly"

    # mask
    goto_download_indiv ${forcing_dir} "mask" 4 "other/flux-forced/mask"

    # xx
    goto_download_indiv ${forcing_dir} "xx" 4 "other/flux-forced/xx"


    # emu_ref
    if [[ $emu_choice -eq 0 || $emu_choice -eq 1 || $emu_choice -eq 3  || $emu_choice -eq 4 || $emu_choice -eq 5 ]]; then

	goto_download_indiv ${emu_input_dir} "emu_ref" 7 "other/flux-forced/emu_input/emu_ref"

    fi

    # forcing 
    if [[ $emu_choice -eq 0 || $emu_choice -eq 2 || $emu_choice -eq 3 ]]; then

	goto_download_indiv "${forcing_dir}/other/flux-forced" "forcing" 6 "other/flux-forced/forcing"

    fi

    # state_weekly
    if [[ $emu_choice -eq 0 || $emu_choice -eq 5 ]]; then

	goto_download_indiv "${forcing_dir}/other/flux-forced" "state_weekly" 6 "other/flux-forced/state_weekly"

	# Create circulation fields for adjoint tracer 

	goto_download_indiv "${emu_input_dir}" "scripts" 8 "other/flux-forced/emu_input/emu_misc/scripts"

	adstateweeklydir=${forcing_dir}/other/flux-forced/state_weekly_rev_time_227808
	if [ ! -d "${adstateweeklydir}" ]; then 
	    echo 
	    echo "Generating adjoint tracer input by reverseintime_all.sh"
	    tempdir=$PWD
	    cd ${forcing_dir}/other/flux-forced
	    ln -sf ${emu_input_dir}/scripts/* .
	    sh -xv ./reverseintime_all.sh
	    cd $tempdir
	fi
    fi

    # emu_msim
    if [[ $emu_choice -eq 0 || $emu_choice -eq 4 ]]; then

	goto_download_indiv ${emu_input_dir} "emu_msim" 7 "other/flux-forced/emu_input/emu_msim"

    fi

    # ---------------------------------------
    # 5) End

    # Record the end time
    end_time=$(date +%s)

    # Calculate the difference from start_time
    elapsed_time=$((end_time - start_time))

    hours=$((elapsed_time / 3600))
    minutes=$(((elapsed_time % 3600) / 60))
    seconds=$((elapsed_time % 60))

    echo 
    echo "Successfully set up EMU input by emu_download_input.sh"
    printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
    echo "emu_download_input_4batch.sh execution complete. $(date)"
    echo 

