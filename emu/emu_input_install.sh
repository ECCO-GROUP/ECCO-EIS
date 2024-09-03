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

# ----------------------------------------
# EMU useraccess directory

emu_userinterface_dir=PUBLICDIR

currentdir=$PWD
cd ${emu_userinterface_dir}

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
goto_download_indiv ${forcing_dir} "input_init" 4 "input_init"

# forcing_weekly
goto_download_indiv ${forcing_dir} "other/flux-forced/forcing_weekly" 4 "other/flux-forced/forcing_weekly"

# mask
goto_download_indiv ${forcing_dir} "other/flux-forced/mask" 4 "other/flux-forced/mask"

# xx
goto_download_indiv ${forcing_dir} "other/flux-forced/xx" 4 "other/flux-forced/xx"


# emu_ref
if [[ $emu_input -eq 0 || $emu_input -eq 1 || $emu_input -eq 3  || $emu_input -eq 4 || $emu_input -eq 5 ]]; then
    
    goto_download_indiv ${emu_input_dir} "emu_ref" 7 "other/flux-forced/emu_input/emu_ref"
    
fi

# forcing 
if [[ $emu_input -eq 0 || $emu_input -eq 2 || $emu_input -eq 3 ]]; then
    
    goto_download_indiv "${forcing_dir}/other/flux-forced" "forcing" 6 "other/flux-forced/forcing"
    
fi

# state_weekly
if [[ $emu_input -eq 0 || $emu_input -eq 5 ]]; then
    
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
if [[ $emu_input -eq 0 || $emu_input -eq 4 ]]; then
    
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

echo " "
echo "----------------------"
echo "Successfully set up EMU input by emu_input_install.sh"
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
echo "emu_input_install.sh execution complete. $(date)"

echo 
cd ${currentdir}
