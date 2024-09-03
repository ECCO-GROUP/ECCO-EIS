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

emu_userinterface_dir=PUBLICDIR

# ***************************************
# 1) Enter Earthdata username & WebDAV password 

echo
echo "----------------------"
URL="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced"

while true; do
    # Prompt for username
    read -p "Enter your Earthdata username: " Earthdata_username

    # Prompt for password
    read -p "Enter your WebDAV password (*NOT* Earthdata password): " WebDAV_password
    echo

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
        echo "Invalid username and/or password. Try again."
	echo
    fi
done

sleep 2

# ---------------------------------------
# 2) Select what to download 

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


# ----------------------------------------
# Downloading EMU Input

echo
echo "----------------------"
echo "Download EMU Input ... "

# Choose between interactive or batch 
echo
echo "This can take a while (~13 hours if downloading all input files). "
echo 
echo "Choose to download interactively (1) or by batch job (2) ... (1/2)?"
echo "(For option 2, see README_input_setup before proceeding.)"
read fmode 
echo 
echo "Done with user input."

if [[ $fmode -eq 1 ]]; then 

    echo
    echo "----------------------"
    echo "Downloading EMU Input interactively as a background job ... "
    log_file="${emu_userinterface_dir}/emu_input_setup.log"
    echo
    echo "Progress can be monitored in file " ${log_file}
    echo "  tail ${log_file} "

    ${emu_userinterface_dir}/emu_input_install.sh <<EOF > "$log_file" 2>> "$log_file" &
${Earthdata_username}
${WebDAV_password}
${emu_input}
EOF
    emu_input_install_pid=$!
    
    echo "Downloading EMU's Input Files pid is " $emu_input_install_pid

    echo 
    sleep 2

    echo "----------------------"
    echo " Waiting for completion of background job ... "
    echo 
    echo "***********************************"
    echo " Do not terminate this script until it completes on its own. "
    echo "***********************************"

    check_job() {
	if ps -p $1 > /dev/null; then
	    echo 
	    echo "$2 is still running." 
	    echo "PID is $1"
	    echo "Check progress in log file $3"
	    echo "Waiting for this job to finish..."
	    wait $1
	    # Check the exit status of the background job
	    if [ $? -ne 0 ]; then
		echo 
		echo "***********************************"
		echo "$2 has failed."
		echo "Check log file $3"
		echo "***********************************"
	    else
		echo 
		echo "$2 has finished."
	    fi
	else
	    echo 
	    #    echo "$2 is already finished or failed to start."
	    echo "$2 is finished already."
	    echo "Check log file $3"
	    echo 
	fi
    }

    check_job ${emu_input_install_pid} "EMU Input File setup" "${log_file}"

else
    echo
    echo "----------------------"
    echo "Downloading EMU Input in batch job by submitting "
    echo "pbs_input_setup.sh to the batch system "

    returndir=$PWD
    cd ${emu_userinterface_dir}

    cp ./pbs_input_setup.sh ./pbs_input_setup_actual.sh 
    sed -i -e "s|EARTHDATA_USERNAME|${Earthdata_username}|g" ./pbs_input_setup_actual.sh 
    sed -i -e "s|WEBDAV_PASSWORD|${WebDAV_password}|g" ./pbs_input_setup_actual.sh 
    sed -i -e "s|EMU_INPUT|${emu_input}|g" ./pbs_input_setup_actual.sh 
    
    BATCH_COMMAND ./pbs_input_setup_actual.sh    

    # Delete file with Earthdata credentials 
    rm ./pbs_input_setup_actual.sh    

    cd ${returndir}
fi
echo

