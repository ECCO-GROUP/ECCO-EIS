#!/bin/bash -e 

# This version, for singularity, uses setup scripts from Github instead 
# those in the sif file. 

umask 022

# Record the start time
start_time=$(date +%s)

#=================================
# A consolidated shell script to set up EMU. 
# Includes 
#    1) Set up EMU (in emu_dir)
#       a) Select mode (native, singularity, docker) 
#       b) Set up MPI if singularity or docker
#    2) Download input files (in emu_input_dir)
#    3) Install user access files (in emu_userinterface_dir)
#
#=================================

echo 
echo "------------------------------------------------------------------------------"
echo " This script sets up EMU, a collection of computational tools for analyzing"
echo " the ECCO model (flux-forced version of ECCO Version 4 Release 4). The Tools "
echo " include the following;"
echo 
echo "   1) Sampling (samp); Evaluates state time-series from model output."
echo "   2) Forward Gradient (fgrd); Computes model's forward gradient."
echo "   3) Adjoint (adj); Computes model's adjoint gradient."
echo "   4) Convolution (conv); Evaluates adjoint gradient decomposition."
echo "   5) Tracer (trc); Computes passive tracer evolution."
echo "   6) Budget (budg); Evaluates budget time-series from model output."
echo "   7) Modified Simulation (msim); Re-runs model with modified input."
echo "   8) Attribution (atrb); Evaluates state time-series by control type."
echo "   9) Auxiliary (aux): Generates user input files for other EMU tools."
echo 
echo " EMU includes programs (Matlab, Python, IDL) for interactively reading and "
echo " plotting the Tools' results. " 
echo
echo "************************"
echo " This script will install EMU's Programs (~1GB), its User Interface (~2MB), "
echo " and download its Input Files (~1TB) to user-specified directories. "
echo 
echo " Users should not move or alter these directories or their files unless "
echo " noted otherwise (e.g., conforming batch scripts pbs_*.sh for the host " 
echo " system, installed in the User Interface directory). Once installed, "
echo " any user of the host system should be able to utilize the installed files "
echo " and programs; Separate installations for different users are not necessary. "
echo 
echo " Installation requires obtaining a NASA Earthdata account for downloading "
echo " files from https://ecco.jpl.nasa.gov/drive/. Enter your Earthdata "
echo " username and WebDAV password (not your Earthdata password) at the prompts "
echo " below. The WebDAV password can be found at this URL after logging in with "
echo " your Earthdata username and Earthdata password, or click the 'Back to "
echo " WebDAV Credentials' button when browsing files at the URL."
echo 
echo " See the README file that will be installed in the User Interface directory "
echo " for details of EMU, including instructions on how to use it."
echo "************************"
echo 
echo "*****************************************************************"
echo " This is an alpha version of EMU. " 
echo " Please direct any issues and/or questions to Ichiro Fukumori (fukumori@jpl.nasa.gov). " 
echo "*****************************************************************"
echo 
echo "Press ENTER key to continue ... "
read ftemp

# ***************************************
# 0) Set trap to kill background jobs in case this script is terminated prematurely. 

# Define an array to hold background process IDs
bg_pids=()

# Function to clean up background processes
cleanup() {
    echo "Cleaning up background processes..."
    for pid in "${bg_pids[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 1
}

# Trap SIGINT, SIGTERM, and SIGQUIT and call the cleanup function
# Does not trap SIGHUP
trap cleanup SIGINT SIGTERM SIGQUIT


# ***************************************
# 1) Enter Earthdata username & WebDAV password (for downloading EMU's Input Files)

echo
echo "----------------------"
#URL="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced"
URL="https://ecco.jpl.nasa.gov/drive"

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
	if echo "$OUTPUT" | grep -Ei "Username/Password Authentication Failed|Authorization failed" > /dev/null; then
            echo "Invalid username and/or password. Try again."
            echo
	else
	    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "ERROR: wget to $URL. Issue may be with server or client." 
            echo "       wget returns the following." 
	    echo 
            echo "$OUTPUT"
	    echo 
	    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
	    echo 
            exit 1
	fi
    fi
done

sleep 2

# ***************************************
# 2) Select directory for storing EMU's Programs

echo
echo "----------------------"
echo "Enter directory name (emu_dir) to download and set up EMU's Programs (~1 GB) "
echo "or press the ENTER key to use EMU's default (emu_dir under the present directory) ... ?"
read ftext 

if [[ -z ${ftext} ]]; then
    emu_dir=emu_dir
else
    emu_dir=${ftext}
fi

# Check to make sure directory exists.
if [[ ! -d "${emu_dir}" ]]; then
    mkdir ${emu_dir} 
fi

# Convert emu_dir to absolute pathname 
emu_dir=$(readlink -f "$emu_dir")

echo
echo "EMU's Programs will be installed in " 
echo $emu_dir 
sleep 1

# ***************************************
# 3) Select directory for storing EMU's User Interface 

echo
echo "----------------------"
echo "Enter directory name (emu_userinterface_dir) to install EMU's User Interface"
echo "(~2 MB) or press the ENTER key to use EMU's default (emu_userinterface_dir "
echo "under the present directory) ... ?" 
read ftext 

if [[ -z ${ftext} ]]; then
    emu_userinterface_dir=emu_userinterface_dir
else
    emu_userinterface_dir=${ftext}
fi

# Check if emu_userinterface_dir exists
if [[ ! -d "${emu_userinterface_dir}" ]]; then
	mkdir ${emu_userinterface_dir} 
fi

# Convert emu_userinterface_dir to absolute pathname 
emu_userinterface_dir=$(readlink -f "$emu_userinterface_dir")

# Make sure directory is different from emu_dir 
if [[ ${emu_userinterface_dir} == ${emu_dir} ]]; then
    echo 
    echo "Directory emu_userinterface_dir cannot be the same as emu_dir ... "
    echo "Using default emu_userinterface_dir ... " 

    emu_userinterface_dir=emu_userinterface_dir
    if [[ ! -d "${emu_userinterface_dir}" ]]; then
	mkdir ${emu_userinterface_dir} 
    fi
    emu_userinterface_dir=$(readlink -f "$emu_userinterface_dir")
fi

echo
echo "EMU's User Interface will be installed in " 
echo $emu_userinterface_dir
sleep 1


# ***************************************
# 4) Select directory for storing EMU's Input Files 

echo
echo "----------------------"
echo "Enter directory name (emu_input_dir) to download up to 1.1 TB of EMU's Input "
echo "Files or press the ENTER key to use EMU's default (emu_input_dir under the "
echo "present directory) .... ? "
read ftext 

if [[ -z ${ftext} ]]; then
    emu_input_dir=emu_input_dir
else
    emu_input_dir=${ftext}
fi

# Check if emu_input_dir exists
if [[ ! -d "${emu_input_dir}" ]]; then
    mkdir ${emu_input_dir} 
fi

# Convert emu_input_dir to absolute pathname 
emu_input_dir=$(readlink -f "$emu_input_dir")

# Make sure directory is different from emu_dir 
if [[ ${emu_input_dir} == ${emu_dir} ]] || [[ ${emu_input_dir} == ${emu_userinterface_dir} ]]; then
    echo 
    echo "Directory emu_input_dir cannot be the same as emu_dir or emu_userinterface_dir... "
    echo "Using default emu_input_dir ... " 

    emu_input_dir=emu_input_dir
    if [[ ! -d "${emu_input_dir}" ]]; then
	mkdir ${emu_input_dir} 
    fi
    emu_input_dir=$(readlink -f "$emu_input_dir")
fi

echo 
echo "EMU's Input Files will be downloaded to " 
echo ${emu_input_dir}
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

echo
echo "************************"
echo "NOTE: See *.log files in ${setup_dir} should this script fail."
echo "************************"
sleep 1 

# ***************************************
# 6) Select type of installation for EMU's Programs

echo 
echo "----------------------"
echo "EMU's Programs can be installed in two different ways;"
echo "   1) Compiling source code on host (native) " 
echo "   2) Using Singularity image (singularity)"
#echo "   3) Using Docker image (docker)"
echo 
echo "Option 1) requires a TAF license to derive the MITgcm adjoint used by EMU's "
#echo "Adjoint Tool. Options 2) and 3) have compiled versions of the code in "
echo "Adjoint Tool. Option 2) has compiled versions of the code in "
echo "containerized form that do not require a separate TAF license to use."
echo
echo "Either choice also installs programs in Python, Matlab, and IDL for "
echo "interactively reading and plotting EMU's results (emu_plot). Users "
echo "interested in installing only these reading and plotting routines "
echo "without installing EMU's Tools themselves, may choose to enter 0 below. " 
echo 
#echo "Enter choice for type of EMU implementation ... (1-3)?"
echo "Enter choice for type of EMU implementation ... (1, 2, or 0)?"
read emu_type 

#while [[ ${emu_type} -lt 1 || ${emu_type} -gt 3 ]] ; do 
#    read -p "Choice must be 1-3. " emu_type
while [[ ${emu_type} -lt 0 || ${emu_type} -gt 2 ]] ; do 
    read -p "Choice must be 1, 2, or 0. " emu_type
done

# Check availablity of singularity 
if [[ ${emu_type} -eq 2 ]] && ! (command -v singularity &> /dev/null) ; then
    echo 
    echo "**********************"
    echo "Command singularity not found."
    echo "Singularity must be available on host system to proceed." 
    echo "Aborting emu_setup.sh ... "
    exit 1
fi

echo
echo "Implementation type choice is "${emu_type}

sleep 2

# ***************************************
# 7) Set batch command

batch_command=bash

if [[ "$emu_type" -ne 0 ]]; then

echo 
echo "----------------------"
echo "EMU uses batch scripts to run some of its tools in PBS (Portable "
echo "Batch System). The PBS commands in these shell scripts (pbs_*.sh),"
echo "installed in EMU's User Interface directory (emu_userinterface_dir)"
echo $emu_userinterface_dir
echo "may need to be revised for different batch systems and/or different hosts. "
echo "Alternatively, these shell scripts can be run interactively if sufficient "
echo "resources are available."
echo
echo "Enter the command for submitting batch jobs (e.g., qsub, sbatch, "
echo "bsub <, condor_submit, msub) or press the ENTER key to have EMU "
echo "run its batch scripts interactively ... ?"
read ftext

echo 
if [[ -z ${ftext} ]]; then
    echo "EMU's batch job scripts will be run interactively."
else
    if ! (command -v ${ftext} &> /dev/null) ; then
	echo "Command ${ftext} not found."
	echo "Aborting emu_setup.sh ... "
	exit 1
    fi
    batch_command=${ftext}
    echo "Command to submit EMU's batch job scripts will be: ${batch_command}"
fi
sleep 2 

# ***************************************
# 8a) Select what EMU Input Files to download 

echo 
echo "----------------------"
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
echo "or press the ENTER key to skip this step, which can take a while" 
echo "(~13 hours if downloading all input files.) "
echo 
echo "EMU's Input Files can be downloaded later with shell script"
echo "   ${emu_userinterface_dir}/emu_input_setup.sh "
echo "See "
echo "   ${emu_userinterface_dir}/README_input_setup "
echo "for additional detail, including options to download the input"
echo "in batch mode."
echo 
echo "Enter Input Files download choice ... ?"
read emu_input 

if [[ -z ${emu_input} ]]; then
    emu_input=-1
    echo 
    echo "Input Files will not be downloaded during EMU set up."
else
    while [[ ${emu_input} -lt 0 || ${emu_input} -gt 5 ]] ; do 
	read -p "Choice must be 0-5." emu_input
    done

    echo 
    echo "Input Files download choice is "$emu_input
fi

sleep 2

fi  # end of [emu_type -ne 0] condition 

# ***************************************
# 8b) Download EMU's Input Files

goto_download_input_files() {

echo
echo "----------------------"

if [[ "$emu_input" -ge 0 && "$emu_input" -le  5 ]]; then 
    echo "Downloading EMU's Input Files in the background in "
    echo ${emu_input_dir}

    log_file="${setup_dir}/emu_input_setup.log"
    echo
    echo "This can take a while (~13 hours if downloading all input files). "
    echo "Progress can be monitored in file " ${log_file}
    echo "  tail ${log_file} "

    ${emu_userinterface_dir}/emu_input_install.sh <<EOF > "$log_file" 2>> "$log_file" &
${Earthdata_username}
${WebDAV_password}
${emu_input}
EOF
    emu_input_install_pid=$!
    bg_pids+=($emu_input_install_pid)
    
# Check if the pid was assigned
    echo 
    if [ -z "$emu_input_install_pid" ]; then
        echo "Failed to start the background job or assign pid."
	echo "Run ${emu_userinterface_dir}/emu_input_setup.sh manually." 
    else
	echo "Downloading EMU's Input Files pid is " $emu_input_install_pid
    fi
else
    echo "Skipping downloading EMU's Input Files."
fi

sleep 2

} 
# ------------------  end goto_download_input_files


# ***************************************
# 9) Download and Compile OpenMPI (for use with Singularity image)

goto_openmpi_compile() {
    echo 
    echo "----------------------"

    if [[ "$emu_openmpi" -eq 1 ]]; then 

	# .......................................
	# Download and compile OpenMPI that is compatible with EMU
	# if it doesn't exist already 

	cd $setup_dir

	if [ ! -e "${native_mpiexec}" ] ; then
	    compile_openmpi=true
	    echo "Download and compiling EMU compatible OpenMPI in the background in "
	    echo ${native_ompi}

	    log_file="${setup_dir}/emu_openmpi_setup.log"
	    echo 
	    echo "This can take a while (~30 minutes). "
	    echo "Progress can be monitored in file " ${log_file}
	    echo "  tail ${log_file} "

	    ${emu_userinterface_dir}/emu_openmpi_install.sh  > "$log_file" 2>> "$log_file" &

	    emu_openmpi_install_pid=$!
	    bg_pids+=($emu_openmpi_install_pid)

	    # Check if the pid was assigned
	    echo
	    if [ -z "$emu_openmpi_install_pid" ]; then
		echo "Failed to start the background job or assign pid."
		echo "Run ${setup_dir}/emu_openmpi_setup.sh manually." 
	    else
		echo "Download and compiling OpenMPI pid is " ${emu_openmpi_install_pid}
	    fi

	    sleep 2 

	else
	    compile_openmpi=false 
	    echo
	    echo "EMU compatible OpenMPI is present: "${native_mpiexec}
	    echo "Skipping downloading and compiling OpenMPI."
	    sleep 1
	fi
    else
	echo 
	echo "Skipping downloading and compiling OpenMPI."
	sleep 1
    fi
} 
# ------------------  end goto_openmpi_compile()


# ***************************************
# 10) Install EMU's Programs 

# ------------------
goto_plot_only() {
# .......................................
# End of user input for native installation 
    echo
    echo "**********************"
    echo " End of user input for EMU setup "
    echo " Rest of this script is conducted without user input." 
    #echo 
    #echo " See "
    #echo "   ${emu_userinterface_dir}/README_plot" 
    #echo " for a brief description of tools for interactively "
    #echo " reading and plotting EMU's results."
    sleep 2 

# .......................................
# Download EMU source code from github
    cd ${emu_dir}

    log_file="${setup_dir}/download_emu_source.log"
   (
    git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
    mv ECCO-EIS/emu .  
    rm -rf ECCO-EIS  
#    tar -xvf /net/b230-304-t3/ecco_nfs_1/shared/EMU/singularity8/emu.tar
    ) > "$log_file" 2>> "$log_file"    

    echo
    sleep 2

# .......................................
# Goto setup_dir
    cd $setup_dir 

# .......................................
# Install EMU User Interface (equivalent of install_emu_access.sh)
    if [ ! -d ${emu_userinterface_dir} ]; then
	mkdir ${emu_userinterface_dir}
    fi

    # ----------------------------------------
    # Installing emu_plot & EMU User Guide
    cp -p -f -r ${emu_dir}/emu/emu_plot/* ${emu_userinterface_dir}
    cp -p ${emu_dir}/emu/Guide*.pdf ${emu_userinterface_dir}

    # ----------------------------------------
    # Setup emu_env.native for emu_plot (equivalent of emu_env.sh)
    sed -i -e "s|PUBLICDIR|${emu_userinterface_dir}|g" ${emu_userinterface_dir}/README*
    echo 'emudir_'${emu_dir} > ${emu_userinterface_dir}/emu_env.native 
    echo 'emuinputdir_'${emu_input_dir} >> ${emu_userinterface_dir}/emu_env.native 
    echo 'batch_bash'  >> ${emu_userinterface_dir}/emu_env.native
    echo 'emunproc_13'  >> ${emu_userinterface_dir}/emu_env.native

# .......................................
# Download EMU Input Files needed by emu_plot (equivalente of emu_input_install.sh)

    target_dir="${emu_input_dir}/emu_ref"
    mkdir -p "$target_dir"

    base_url="https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced/emu_input/emu_ref"

    files=(
	XC.data YC.data RC.data DXC.data DYC.data DRC.data
	XG.data YG.data DXG.data DYG.data RF.data DRF.data
	hFacC.data hFacW.data hFacS.data AngleCS.data AngleSN.data
	RAC.data RAS.data RAW.data RAZ.data
    )

    log_file="${setup_dir}/emu_input_setup.log"
    
    {
	echo "Starting download EMU Input Files for plotting into $target_dir"
	date

	for f in "${files[@]}"; do
	    echo "  Downloading $f ..."
	    wget -N -c --no-verbose \
		--user "$Earthdata_username" \
		--password "$WebDAV_password" \
		-P "$target_dir" \
		"$base_url/$f"
	done

	echo " All downloads completed."
	date
    } | tee -a "$log_file"

}
# ------------------  end goto_plot_only

# ------------------
goto_native() {
# .......................................
# Choose number of CPU cores (nproc) for running MITgcm 
    echo 
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

    sleep 2 

# .......................................
# End of user input for native installation 
    echo
    echo "**********************"
    echo " End of user input for EMU setup "
    echo " Rest of this script is conducted without user input." 
    #echo 
    #echo " EMU can be run by entering command " 
    #echo "   ${emu_userinterface_dir}/emu "
    #echo " upon completion of this script and downloading EMU input"
    #echo " if done separately. See "
    #echo "   ${emu_userinterface_dir}/README" 
    #echo " for a brief description, including tools for interactively "
    #echo " reading and plotting the Tools' results."
    sleep 2 

# .......................................
# Installing EMU natively on host system
    echo 
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
#    tar -xvf /net/b230-304-t3/ecco_nfs_1/shared/EMU/singularity8/emu.tar
    ) > "$log_file" 2>> "$log_file"    

# Compile EMU
    cd emu
    log_file="${setup_dir}/make_all_emu.log"
    make all > "$log_file" 2>> "$log_file" 

    echo
    sleep 2

# .......................................
# Goto setup_dir
    cd $setup_dir 

# .......................................
# Compile MITgcm 
# (This cannot be placed in background because install_emu_access.sh checks
# what MITgcm executable is available.) 
    echo 
    echo "----------------------"
    echo "Download and compiling MITgcm and its adjoint in "
    echo ${emu_dir}/emu/exe/nproc

    log_file="${setup_dir}/emu_compile_mdl.log"
    echo "This can take a while (~30 minutes). "
    echo "Progress can be monitored in file " ${log_file}
    echo "  tail ${log_file} "

    ${emu_dir}/emu/native/emu_compile_mdl.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_nproc}
EOF


# .......................................
# Install EMU User Interface 
    echo 
    echo "----------------------"
    echo "Installing EMU's User Interface in "
    echo ${emu_userinterface_dir}

    log_file="${setup_dir}/install_emu_access.log"
    echo
    echo "Progress can be monitored in file " $log_file 

    ${emu_dir}/emu/native/install_emu_access.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_userinterface_dir}
${emu_input_dir}
${batch_command}
${emu_nproc}



EOF

# .......................................
# Download EMU Input Files 
    goto_download_input_files

}
# ------------------  end goto_native

# ------------------
goto_singularity() {

    # .......................................
    # Download EMU source code from github
    # (To use up-to-date scripts from github than those from sif.) 
    echo
    echo "----------------------"
    echo "Installing EMU programs and shell scripts from GitHub to directory "
    echo ${emu_dir}

    cd ${emu_dir}
    log_file="${setup_dir}/download_emu_source.log"
    (
	git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
	mv ECCO-EIS/emu .  
	rm -rf ECCO-EIS  
	#    tar -xvf /net/b230-304-t3/ecco_nfs_1/shared/EMU/singularity8/emu.tar
    ) > "$log_file" 2>> "$log_file"    
    
    # .......................................
    # Download EMU Singularity image
    echo
    echo "----------------------"
    echo "Installing EMU Singularity image (emu.sif) in directory "
    echo ${emu_dir}
    echo
    wget -P ${emu_dir} -r --no-parent --user $Earthdata_username \
	--password $WebDAV_password -nH \
	--cut-dirs=8 https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/other/flux-forced/emu_input/emu_misc/emu.sif 
    chmod a+x ${emu_dir}/emu.sif
    singularity_image=${emu_dir}/emu.sif

    # .......................................
    # Select whether to compile OpenMPI now or later
    echo 
    echo "----------------------"
    echo "EMU Singularity (emu.sif) requires compilation of compatible OpenMPI " 
    echo "which can take ~30min. Enter 1 to compile OpenMPI now as a background "
    echo "job or press the ENTER key to skip this step. "
    echo 
    echo "EMU compatible OpenMPI can be compiled later with shell script "
    echo " ${emu_userinterface_dir}/emu_openmpi_setup.sh "
    echo "See "
    echo "   ${emu_userinterface_dir}/README_openmpi_setup "
    echo "for additional detail, including options to install OpenMPI"
    echo "in batch mode."
    echo 
    echo "Enter 1 to compile now or press the ENTER key to skip ... ?"
    read ftext 

    if [[ -z ${ftext} ]] || [[ ${ftext} -ne 1 ]] ; then
	emu_openmpi=-1 
	echo 
	echo "Skipping downloading and compiling OpenMPI."
    else
	emu_openmpi=1 
	echo 
	echo "OpenMPI will be downloaded and compiled." 
    fi
    
    # .......................................
    # Get shell scripts from EMU intallation 

    cd $setup_dir

    cp -f ${emu_dir}/emu/singularity/install_emu_access.sh .

    # .......................................
    # Set number of nodes to use for MITgcm
    echo
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
    sleep 2 

    # .......................................
    # End of user input for singularity installation 
    echo
    echo "**********************"
    echo " End of user input for EMU setup "
    echo " Rest of this script is conducted without user input." 
    #echo 
    #echo " EMU can be run by entering command " 
    #echo "   ${emu_userinterface_dir}/emu "
    #echo " upon completion of this script and setting up EMU Input "
    #echo " and EMU compatible OpenMPI if done separately. See "
    #echo "   ${emu_userinterface_dir}/README" 
    #echo " for a brief description, including tools for interactively "
    #echo " reading and plotting the Tools' results."
    sleep 2

    # .......................................
    # Install EMU User Interface 
    echo
    echo "----------------------"
    echo "Installing EMU's User Interface in "
    echo ${emu_userinterface_dir}

    native_ompi=${emu_dir}/ompi
    native_mpiexec=${native_ompi}/bin/mpiexec

    log_file="${setup_dir}/install_emu_access.log"
    echo "Progress can be monitored in file " $log_file 

    ./install_emu_access.sh <<EOF > "$log_file" 2>> "$log_file" 
${emu_userinterface_dir}
${singularity_image}
${emu_input_dir}
${native_ompi}
${native_mpiexec}
${batch_command}
${emu_nproc}



EOF

    # .......................................
    # Download EMU Input Files 
    goto_download_input_files

    # .......................................
    # Download and compile OpenMPI that is compatible with EMU
    goto_openmpi_compile

}
# ------------------  end goto_singularity

# ------------------

if [[ "$emu_type" -eq 0 ]]; then
    goto_plot_only
elif [[ "$emu_type" -eq 1 ]]; then
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
# 11) Monitor background task completion 

check_job() {
if ps -p $1 > /dev/null; then
    echo 
    echo "$2 is still running." 
    echo "pid is $1"
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
    echo "$2 is already finished."
fi
}

# ------------------
# Check background jobs if any 
if [ ${#bg_pids[@]} -gt 0 ]; then

    echo
    echo "----------------------"
    echo " Waiting for completion of background jobs ... "
    for pid in "${bg_pids[@]}"; do
        echo "  pid $pid" 
    done
    echo 
    echo "***********************************"
    echo " Do not terminate this script until it completes on its own. "
    echo "***********************************"


    # Monitor setup of EMU's Programs 
    if [[ "$emu_type" -eq 2 ]]; then

	# Check OpenMPI setup 
	if [ "$compile_openmpi" = true ]; then
	    check_job ${emu_openmpi_install_pid} "EMU compatible OpenMPI setup" "${setup_dir}/emu_openmpi_setup.log"
	fi
	
    elif [[ "$emu_type" -eq 3 ]]; then    
	echo 
	echo "Not yet available .... "
    fi

    # Monitor setup of EMU's Input Files 
    if [[ ! "$emu_input" -eq -1 ]]; then 
	check_job ${emu_input_install_pid} "EMU Input File setup" "${setup_dir}/emu_input_setup.log"
    fi

fi

# ***************************************
# 12) End 

# Print Reminders
if [[ "$emu_type" -ne 0 ]]; then

echo
echo "***********************************"
if [[ "$emu_type" -eq 2 ]] && [[ ! -e "${native_mpiexec}" ]] ; then
    echo "Compile EMU compatible OpenMPI skipped during present setup with shell script "
    echo " ${emu_userinterface_dir}/emu_openmpi_setup.sh "
    echo
fi
if [[ "$emu_input" -eq -1 ]]; then 
    echo "Download EMU Input Files skipped during present setup with shell script "
    echo " ${emu_userinterface_dir}/emu_input_setup.sh "
    echo
fi
echo "Upon completion, EMU can be run by entering command " 
echo "   ${emu_userinterface_dir}/emu "
echo 
echo "See "
echo "   ${emu_userinterface_dir}/README" 
echo "for a brief description, including tools for interactively "
echo "reading and plotting EMU's results."
echo "***********************************"

else

echo
echo "***********************************"
echo "Programs for interactive reading and plotting EMU's results (emu_plot) "
echo "has been intalled. See "
echo "   ${emu_userinterface_dir}/README_plot" 
echo "for a brief description."
echo "***********************************"

fi  # end of [emu_type -ne 0] condition 

sleep 5

# Record the end time
end_time=$(date +%s)

# Calculate the difference from start_time
elapsed_time=$((end_time - start_time))

hours=$((elapsed_time / 3600))
minutes=$(((elapsed_time % 3600) / 60))
seconds=$((elapsed_time % 60))

echo 
echo "----------------------"
echo "emu_setup.sh execution complete. $(date)"
printf "Elapsed time: %d:%02d:%02d\n" $hours $minutes $seconds
echo "----------------------"

