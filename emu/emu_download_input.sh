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
echo "-------------------------------------------------------------------------------------------------------"

# ---------------------------------------
# 1) Enter Earthdata username & password

URL="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced"

while true; do
    # Prompt for username
    read -p "Enter your Earthdata username: " Earthdata_username

    # Prompt for password
    read -p "Enter your WebDAV password: " WebDAV_password
    echo

    # Disable exit on error
    set +e

    # Check credentials using wget --spider
    OUTPUT=$(wget --spider --user="$Earthdata_username" --password="$WebDAV_password" "$URL" 2>&1)

    # Enable exit on error
    set -e 

    # Check the exit status of wget
    if echo "$OUTPUT" | grep -q "Authorization failed"; then
        echo "Invalid username or password. Please try again."
    else
        echo "Credentials confirmed"
        break
    fi
done

# ---------------------------------------
# 2) Select directory for EMU
#    Input files will be placed in subdirectories. 
echo " "
echo "Enter directory name to place EMU Input (emu_input_dir) ... ?"
read emu_input_dir

# Check if emu_input_dir exists
if [[ ! -d "${emu_input_dir}" ]]; then
    echo " "
    echo "Directory " ${emu_input_dir} " does not exist."
    echo "Creating " ${emu_input_dir} " ..... "
    mkdir ${emu_input_dir} 
fi

# Convert emu_input_dir to absolute pathname 
emu_input_dir=$(readlink -f "$emu_input_dir")

echo " "
echo "EMU input files will be placed in ... "
echo $emu_input_dir

# ---------------------------------------
# 3) Select what to download 

echo "Choosing what EMU input to download ... "
echo 
echo "EMU's Input Files total 1.1 TB, of which (directory)"
echo "   175 GB (emu_ref) is needed by Sampling, Forward Gradient, Budget, and Attribution"
echo "   195 GB (forcing) is needed by Forward Gradient, Adjoint, Modified Simultion"
echo "   380 GB (state_weekly) is needed by Tracer"
echo "   290 GB (emu_msim) is needed by Attribution" 
echo "   (Convolution Tool uses results of the Adjoint Tool and files downloaded by default.)"
echo 
echo "Choose among the following to download ... "
echo "   0) All Input Files (1.1 TB) "
echo "   1) Files (~175 GB) needed for Sampling and Budget Tools"
echo "   2) Files (~195 GB) needed for Adjoint and Modified Simultion Tools" 
echo "   3) Files (~370 GB) needed for Forward Gradient Tool"
echo "   4) Files (~380 GB) needed for Tracer Tool"
echo "   5) Files (~465 GB) needed for Attribution Tool" 
echo ""
echo "Enter choice ... (0-5)?"
read emu_choice 

while [[ ${emu_choice} -lt 0 || ${emu_choice} -gt 5 ]] ; do 
    echo "Choice must be 0-5."
    read emu_choice
done

echo "Choice is "$emu_choice
echo " " 
if [[ ! $emu_choice -eq 0 ]]; then
    echo "Rerun this script $0 to download additional EMU input, if necessary."
    echo " " 
fi

echo "Done user input. Press ENTER key to begin download which can take a while ... "
read ftemp
echo " "

# ---------------------------------------
# 4) Download Chosen EMU input 

forcing_dir=${emu_input_dir}/forcing
if [[ ! -d "${forcing_dir}" ]]; then
    mkdir ${forcing_dir}
fi

# Download individual directories
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
if [[ $emu_choice -eq 0 || $emu_choice -eq 1 || $emu_choice -eq 3  || $emu_choice -eq 5 ]]; then

    goto_download_indiv ${emu_input_dir} "emu_ref" 7 "other/flux-forced/emu_input/emu_ref"

fi

# forcing 
if [[ $emu_choice -eq 0 || $emu_choice -eq 2 || $emu_choice -eq 3 ]]; then

    goto_download_indiv "${forcing_dir}/other/flux-forced" "forcing" 6 "other/flux-forced/forcing"

fi

# state_weekly
if [[ $emu_choice -eq 0 || $emu_choice -eq 4 ]]; then

    goto_download_indiv "${forcing_dir}/other/flux-forced" "state_weekly" 6 "other/flux-forced/state_weekly"

# Create circulation fields for adjoint tracer 

    goto_download_indiv "${emu_input_dir}" "scripts" 8 "other/flux-forced/emu_input/emu_misc/scripts"

    adstateweeklydir=${forcing_dir}/other/flux-forced/state_weekly_rev_time_227808
    if [ ! -d "${adstateweeklydir}" ]; then 
	echo "Generating adjoint tracer input by reverseintime_all.sh"
	tempdir=$PWD
	cd ${forcing_dir}/other/flux-forced
	ln -sf ${emu_input_dir}/scripts/* .
	sh -xv ./reverseintime_all.sh
	cd $tempdir
    fi
fi

# emu_msim
if [[ $emu_choice -eq 0 || $emu_choice -eq 5 ]]; then

    goto_download_indiv ${emu_input_dir} "emu_msim" 7 "other/flux-forced/emu_input/emu_msim"

fi

# ---------------------------------------
# 5) End
echo " "
echo "Successfully set up EMU input by emu_download_input.sh"
echo 
echo "emu_download_input.sh execution complete. $(date)"


