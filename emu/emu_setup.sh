#!/bin/bash -e 

umask 022

#=================================
# A consolidated shell script to set up EMU. 
# Includes 
#    1) Set up EMU (in emu_dir)
#       a) Select mode (native, singularity, docker) 
#       b) Setup MPI if singularity or docker
#    2) Download input files (in emu_input_dir)
#    3) Install user access files (in emu_userinterface_dir)
#
#=================================

echo 
echo " This script sets up EMU, a collection of computational tools for analyzing"
echo " the ECCO model (flux-forced version of ECCO Version 4 Release 4) that "
echo " includes the following;"
echo 
echo "   1) Sampling (samp); Evaluates state time-series from model output."
echo "   2) Forward Gradient (fgrd); Computes model's forward gradient."
echo "   3) Adjoint (adj); Computes model's adjoint gradient."
echo "   4) Convolution (conv); Evaluates adjoint gradient decomposition."
echo "   5) Tracer (trc); Computes passive tracer evolution."
echo "   6) Budget (budg); Evaluates budget time-series from model output."
echo "   7) Modified Simulation (msim); Re-runs model with modified input."
echo "   8) Attribution (atrb); Evaluates state time-series by control type."
echo
echo "------------------------------------------------------------------------------"
echo " This script will install EMU's Programs (~1GB), its User Interface (~2MB), "
echo " and download its Input Files (up to 1TB) to user-specified directories. "
echo " For downloading the Input Files, users will need to obtain a NASA Earthdata "
echo " account at https://ecco.jpl.nasa.gov/drive/ and enter the corresponding "
echo " Username and WebDAV password (not Earthdata password) at the prompts below."
echo " See the README file that will be installed in the User Interface directory "
echo " for details of EMU including instructions on its usage."
echo "------------------------------------------------------------------------------"
echo 
echo "Press ENTER key to continue ... "
read ftemp

# ***************************************
# 1) Enter Earthdata username & password (for downloading EMU's Input Files)

echo "----------------------"
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
        echo "Invalid username and/or password. Please try again."
    else
        echo "Earthdata Credentials confirmed"
        break
    fi

done

echo
sleep 1

# ***************************************
# 2) Select directory for storing EMU's Programs

echo "----------------------"
echo "Enter directory name (emu_dir) to download and set up EMU's Programs (~1 GB) ... ? "
read ftext 

    emu_dir=${ftext}

    # Check to make sure directory exists.
    if [[ ! -d "${emu_dir}" ]]; then
	mkdir ${emu_dir} 
    fi

    # Convert emu_dir to absolute pathname 
    emu_dir=$(readlink -f "$emu_dir")

    echo
    echo "EMU's Programs will be installed in " 
    echo $emu_dir 

echo
sleep 1

# ***************************************
# 3) Select directory for storing EMU's User Interface 

echo "----------------------"
echo "Enter directory name (emu_userinterface_dir) to install EMU's User Interface"
echo "(~2 MB) or press the ENTER key to use the same directory as EMU's Programs "
echo "(emu_dir) chosen above .... ? "
read ftext 

if [[ -z ${ftext} ]]; then
    emu_userinterface_dir=${emu_dir}
else
    emu_userinterface_dir=${ftext}

    # Check if emu_userinterface_dir exists
    if [[ ! -d "${emu_userinterface_dir}" ]]; then
	mkdir ${emu_userinterface_dir} 
    fi
fi

# Convert emu_userinterface_dir to absolute pathname 
emu_userinterface_dir=$(readlink -f "$emu_userinterface_dir")

echo
echo "EMU's User Interface will be installed in " 
echo $emu_userinterface_dir

echo
sleep 1


# ***************************************
# 4) Select directory for storing EMU's Input Files 

echo "----------------------"
echo "Enter directory name (emu_input_dir) to download up to 1.1 TB of EMU's Input "
echo "Files or press the ENTER key to use the same directory as EMU's Programs "
echo "(emu_dir) chosen above .... ? "
read ftext 

if [[ -z ${ftext} ]]; then
    emu_input_dir=${emu_dir}
else
    emu_input_dir=${ftext}

    # Check if emu_input_dir exists
    if [[ ! -d "${emu_input_dir}" ]]; then
	mkdir ${emu_input_dir} 
    fi
fi

# Convert emu_input_dir to absolute pathname 
emu_input_dir=$(readlink -f "$emu_input_dir")

echo 
echo "EMU's Input Files will be downloaded to " 
echo ${emu_input_dir}
echo
sleep 1

# ***************************************
# 5) Move to emu_dir to begin installation 

start_dir=$PWD
cd $emu_dir
if [[ ! -d temp_setup ]]; then 
    mkdir temp_setup
fi
cd temp_setup
setup_dir=$PWD

# ***************************************
# 6) Select type of installation for EMU's Programs

echo "----------------------"
echo "EMU's Programs can be installed in three different ways;"
echo "   1) Compiling source code on host (native) " 
echo "   2) Using Singularity image (singularity)"
echo "   3) Using Docker image (docker)"
echo 
echo "Option 1) requires a TAF license to derive the MITgcm adjoint used by EMU's "
echo "Adjoint Tool. Options 2) and 3) have compiled versions of the code in "
echo "containerized form that do not require a separate TAF license to use."
echo
echo "Enter choice for type of EMU implementation ... (1-3)?"
read emu_type 

while [[ ${emu_type} -lt 1 || ${emu_type} -gt 3 ]] ; do 
    read -p "Choice must be 1-3. " emu_type
done

echo
echo "Implementation type choice is "${emu_type}

echo 
sleep 2

# ***************************************
# 7) Select what EMU Input Files to download 

echo "----------------------"
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
echo "or press the ENTER key to skip this step. Input Files can be downloaded later "
echo "using shell script"
echo "   ${emu_userinterface_dir}/emu_download_input.sh "
echo 
echo "Enter Input Files download choice ... ?"
read emu_download 

if [[ -z ${ftext} ]]; then
    emu_download=-1
    echo 
    echo "Input Files will not be downloaded during EMU set up."
else
    while [[ ${emu_download} -lt 0 || ${emu_download} -gt 5 ]] ; do 
	read -p "Choice must be 0-5." emu_download
    done

    echo 
    echo "Input Files download choice is "$emu_download
fi

echo 
sleep 2

# ***************************************
# 8) Download EMU's Input Files

goto_download_input_files() {

echo "----------------------"

if [[ "$emu_download" -ge 0 && "$emu_download" -le  5 ]]; then 
    echo "Downloading EMU's Input Files in the background in "
    echo ${emu_input_dir}

    log_file="emu_download_input.log"
    echo
    echo "This can take a while. Progress can be monitored in file " ${log_file}
    echo "  tail ${setup_dir}/${log_file} "

    ./emu_download_input.sh <<EOF > "$log_file" 2>> "$log_file" &
${Earthdata_username}
${WebDAV_password}
${emu_input_dir}
${emu_download}

EOF
    emu_download_input_pid=$!
# Check if the PID was assigned
    echo 
    if [ -z "$emu_download_input_pid" ]; then
        echo "Failed to start the background job or assign PID."
	echo "Run ${PWD}/emu_download_input.sh manually." 
    else
	echo "Downloading EMU's Input Files pid is " $emu_download_input_pid
    fi
else
    echo "Skipping downloading EMU's Input Files."
fi

echo 
sleep 2

} 
# ------------------  end goto_download_input_files

# ***************************************
# 9) Install EMU's Programs 

# .......................................
# Set batch command

echo "----------------------"
echo "EMU provides scripts (pbs_*.sh) to run batch jobs for PBS (Portable Batch System)."
echo "The PBS commands in these scripts may need to be revised for different batch "
echo "systems and/or different hosts. Alternatively, the scripts can be run interactively"
echo "if sufficient resources are available."
echo
echo "Enter the command for submitting batch jobs (e.g., qsub) or enter bash to run "
echo "the scripts interactively ... ?"
read batch_command 

echo 
echo "Command to run EMU's batch job scripts will be: ${batch_command}"
echo 
sleep 2 

# ------------------
goto_native() {
# .......................................
# Choose number of CPU cores (nproc) for running MITgcm 
    echo "----------------------"
    echo "Choose number of CPU cores (nproc) for running MITgcm." 
    echo "Choose among the following nproc ... "
    echo 
    n_exe=(13 36 48 68 72 96 192 360)
    for nproc in "${n_exe[@]}"; do
	echo "$nproc"
    done

    while true; do 
	echo 
	echo "Enter choice for nproc ... ?"
	read emu_nproc
	# make sure choice is available 
	found=false
	for nproc in "${n_exe[@]}"; do
	    if [ "$nproc" = "$emu_nproc" ]; then
		found=true
		break
	    fi
	done
	if [ "$found" = true ]; then
	    break
	else
	    echo 
	    echo "Invalid choice for nproc ... " $emu_nproc
	fi
    done

    echo 
    echo "Number of CPU cores to be used for MITgcm: ${emu_nproc}"

    echo
    sleep 2 

# .......................................
# End of user input for native installation 
    echo "----------------------"
    echo " End of user input to set up EMU "
    echo " Rest of this script is conducted without user input." 
    echo 
    echo " Upon completion of this script, EMU can be run by entering command " 
    echo "   ${emu_userinterface_dir}/emu "
    echo " See "
    echo "   ${emu_userinterface_dir}/README" 
    echo " for a brief description, including tools for interactively "
    echo " reading and plotting the Tools' results."
    echo "----------------------"
    echo 

# .......................................
# Installing EMU natively on host system
    echo "----------------------"
    echo "Download and compiling EMU on host system in directory "
    echo ${emu_dir}

# Download EMU source code from github
    cd ${emu_dir}
    log_file="${setup_dir}/download_emu_source.log"
   (
    git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
    mv ECCO-EIS/emu .  
    rm -rf ECCO-EIS  
#    tar -xvf /nobackup/ifukumor/emu_2/emu.tar 
    ) > "$log_file" 2>> "$log_file"    

# Compile EMU
    cd emu
    log_file="${setup_dir}/make_all_emu.log"
    make all > "$log_file" 2>> "$log_file" 

    echo
    sleep 2

# .......................................
# Download EMU Input Files 
    cd $setup_dir 

    cp -f ${emu_dir}/emu/emu_download_input.sh  .

    goto_download_input_files

# .......................................
# Compile MITgcm 
# (This cannot be placed in background because install_emu_access.sh checks
# what MITgcm executable is available.) 
    echo "Download and compiling MITgcm and its adjoint in "
    echo ${emu_dir}/emu/exe/nproc

    log_file="emu_compile_mdl.log"
    echo "This can take a while. Progress can be monitored in file " $log_file
    echo "  tail ${setup_dir}/${log_file} "

    ${emu_dir}/emu/native/emu_compile_mdl.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_nproc}
EOF

    echo 

# .......................................
# Install EMU User Interface 
    echo "----------------------"
    echo "Installing EMU's User Interface in "
    echo ${emu_userinterface_dir}

    log_file="install_emu_access.log"
    echo
    echo "Progress can be monitored in file " $log_file 

    ${emu_dir}/emu/native/install_emu_access.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_userinterface_dir}
${emu_input_dir}
${batch_command}
${emu_nproc}



EOF

    echo 

}
# ------------------  end goto_native

# ------------------
goto_singularity() {
    cd $setup_dir

# .......................................
# Download EMU Singularity image
    echo "----------------------"
    echo "Installing EMU Singularity image (emu.sif) in directory "
    echo ${emu_dir}
    echo
    wget -P ${emu_dir} -r --no-parent --user $Earthdata_username \
	--password $WebDAV_password -nH \
	--cut-dirs=8 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced/emu_input/emu_misc/emu.sif 
    singularity_image=${emu_dir}/emu.sif
#    singularity_image=/net/b230-304-t3/ecco_nfs_1/shared/EMU/emu_dir/emu_sandbox


# .......................................
# Get scripts from emu Singularity image 
    
   /bin/rm -f my_commands.sh
   echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
   echo 'cd /inside_out'                    >> my_commands.sh

# Get shell scripts 
   echo 'cp -f ${emu_dir}/emu/singularity/install_emu_access.sh .'  >> my_commands.sh
   echo 'cp -f ${emu_dir}/emu/singularity/install_openmpi.sh .'  >> my_commands.sh
   echo 'cp -f ${emu_dir}/emu/emu_download_input.sh  .'  >> my_commands.sh

   singularity exec --bind ${PWD}:/inside_out \
       ${singularity_image} /inside_out/my_commands.sh

# .......................................
# Download EMU Input Files 
    goto_download_input_files

# .......................................
# Download and compile OpenMPI that is compatible with EMU
# if it doesn't exist alread 
    echo "----------------------"
    native_ompi=${emu_dir}/ompi
    native_mpiexec=${native_ompi}/bin/mpiexec

if [ ! -e "${native_mpiexec}" ] ; then
    compile_openmpi=true
    echo "Download and compiling EMU compatible OpenMPI in the backgroudn in "
    echo ${native_ompi}

    log_file="install_openmpi.log"
    echo "This can take a while. Progress can be monitored in file " ${log_file}
    echo "  tail ${setup_dir}/${log_file} "

    ./install_openmpi.sh <<EOF > "$log_file" 2>> "$log_file" &
${native_ompi}
EOF
    install_openmpi_pid=$!

# Check if the PID was assigned
    echo
    if [ -z "$install_openmpi_pid" ]; then
        echo "Failed to start the background job or assign PID."
	echo "Run ${PWD}/install_openmpi.sh manually." 
    else
	echo "Download and compiling OpenMPI pid is " ${install_openmpi_pid}
    fi

    echo 
    sleep 2 

else
    compile_openmpi=false 
    echo "EMU compatible OpenMPI found in "${native_ompi}
    echo 
    sleep 1
fi

# .......................................
# Set number of nodes to use for MITgcm
   echo "----------------------"

   /bin/rm -f my_commands.sh
   echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
   echo 'cd /inside_out'                    >> my_commands.sh

# Search available executables (compiled by singularity/emu_compile_mdl.sh)
   echo 'exe_dir=${emu_dir}/emu/exe/nproc'  >> my_commands.sh
   echo 'n_exe_raw=($(find ${exe_dir} -maxdepth 1 -type d -name "[0-9]*" -printf "%f\n"))'  >> my_commands.sh
   echo 'n_exe=($(for i in "${n_exe_raw[@]}"; do echo $i; done | sort -n))'   >> my_commands.sh
   echo 'if [ ${#n_exe[@]} -eq 0 ]; then '  >> my_commands.sh
   echo '	echo "No executable for MITgcm found in ${exe_dir}" '  >> my_commands.sh
   echo '	echo "Compile MITgcm before installing EMU User Access files with " '  >> my_commands.sh
   echo '       echo "${emu_dir}/emu/singularity/emu_compile_mdl.sh" '  >> my_commands.sh
   echo '	exit 1 '  >> my_commands.sh
   echo 'fi '  >> my_commands.sh

# Print out n_exe for use outside singularity image 
   echo 'rm -f ./n_exe.txt '                >> my_commands.sh
   echo 'for item in "${n_exe[@]}"; do '    >> my_commands.sh
   echo '    echo "$item" >> ./n_exe.txt '  >> my_commands.sh
   echo 'done '                             >> my_commands.sh

   singularity exec --bind ${PWD}:/inside_out \
       ${singularity_image} /inside_out/my_commands.sh

# Search available executables (compiled by singularity/emu_compile_mdl.sh)
   mapfile -t n_exe < ./n_exe.txt

   if [ ${#n_exe[@]} -eq 1 ]; then
       emu_nproc="${n_exe[0]}"
   else
       echo "Enter number of CPU cores (nproc) to use for MITgcm employed by EMU."
       echo "Available options are ... " 
       for nproc in "${n_exe[@]}"; do
	   echo "$nproc"
       done
       echo " "
       
       while true; do 
	   echo "Enter choice for nproc ... ?"
	   read emu_nproc
	   # make sure choice is available 
	   found=false
	   for nproc in "${n_exe[@]}"; do
	       if [ "$nproc" = "$emu_nproc" ]; then
		   found=true
		   break
	       fi
	   done
	   if [ "$found" = true ]; then
	       break
	   else
	       echo "Invalid choice for nproc ... " $emu_nproc
	   fi
       done
   fi

   echo 
   echo "Number of CPU cores to be used for MITgcm: ${emu_nproc}"
   echo
   sleep 2 

# .......................................
# End of user input for singularity installation 
   echo "----------------------"
   echo " End of user input to set up EMU "
   echo " Rest of this script is conducted without user input." 
   echo 
   echo " Upon completion of this script, EMU can be run by entering command " 
   echo "   ${emu_userinterface_dir}/emu "
   echo " See "
   echo "   ${emu_userinterface_dir}/README" 
   echo " for a brief description, including tools for interactively "
   echo " reading and plotting the Tools' results."
   echo "----------------------"
   echo 

# .......................................
# Install EMU User Interface 
echo "----------------------"
echo "Installing EMU's User Interface in "
echo ${emu_userinterface_dir}

log_file="install_emu_access.log"
echo "Progress can be monitored in file " $log_file 

./install_emu_access.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_userinterface_dir}
${singularity_image}
${emu_input_dir}
${native_mpiexec}
${batch_command}
${emu_nproc}



EOF

    echo 

}
# ------------------  end goto_singularity

# ------------------
if [[ "$emu_type" -eq 1 ]]; then
    goto_native
elif [[ "$emu_type" -eq 2 ]]; then
    goto_singularity
elif [[ "$emu_type" -eq 3 ]]; then    
    echo "Not yet available .... "
else 
   echo "This should not happen ... "
   exit 1
fi

# ***************************************
# 10) Install EMU_PLOT

echo "----------------------"
echo "Downloading EMU_PLOT on host system in directory "
echo ${emu_userinterface_dir}

# Download EMU source code from github
cd ${emu_userinterface_dir}
log_file="./setup_emu_plot.log"
(
    git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
    mv ECCO-EIS/emu/emu_plot/* .  
    rm -rf ECCO-EIS  
) > "$log_file" 2>> "$log_file"    

sed -i -e "s|PUBLICDIR|${emu_userinterface_dir}|g" ./README_plot
sed -i -e "s|PUBLICDIR|${emu_userinterface_dir}|g" ./*/README_*

echo

# ***************************************
# 11) Monitor background task completion 

echo "----------------------"
echo " Waiting for completion of background tasks ... "


check_job() {
if ps -p $1 > /dev/null; then
    echo 
    echo "$2 is still running." 
    echo "Waiting for it to finish..."
    wait $1
    # Check the exit status of the background job
    if [ $? -ne 0 ]; then
	echo 
        echo "$2 failed."
        echo "Check log file $3"
    else
	echo 
        echo "$2 completed successfully."
    fi
else
    echo 
    echo "$2 has already finished or failed to start."
    echo "Check log file $3"
fi
}

# Monitor setup of EMU's Programs 
if [[ "$emu_type" -eq 2 ]]; then

# Check OpenMPI setup 
    if [ "$compile_openmpi" = true ]; then
	check_job $install_openmpi_pid "EMU compatible OpenMPI setup" "${setup_dir}/install_openmpi.log"
    fi

elif [[ "$emu_type" -eq 3 ]]; then    
    echo 
    echo "Not yet available .... "
fi

# Monitor setup of EMU's Input Files 
if [[ ! "$emu_download" -eq 0 ]]; then 
    check_job $emu_download_input_pid "EMU Input File setup" "${setup_dir}/emu_download_input.log"
fi

echo 
echo "----------------------"
echo "emu_setup.sh execution complete. $(date)"
echo "----------------------"

