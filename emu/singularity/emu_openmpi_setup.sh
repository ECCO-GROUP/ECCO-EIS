#!/bin/bash -e 
#
# Compile Open MPI for use with EMU Singularity image 
# (Same Open MPI as what's in the image created outside for compatibility.) 
#

umask 022

#=================================
# Download and Compile OpenMPI for EMU (singularity)
#=================================

native_ompi=NATIVE_OMPI
native_mpiexec=NATIVE_MPIEXEC

echo 
echo "------------------------------------------------------------------------------"
echo " This script will compile OpenMPI for use with EMU Singularity. " 

# ----------------------------------------
# Check if MPI already exists
if [ -e "${native_mpiexec}" ] ; then
    echo 
    echo "----------------------"
    echo "EMU compatible OpenMPI is already present: "${native_mpiexec}
    echo "Exiting script." 
    exit
fi

# ----------------------------------------
# ID path to EMU useraccess files 

emu_userinterface_dir=PUBLICDIR

# ----------------------------------------
# Download and Compile OpenMPI for EMU 

echo
echo "----------------------"
echo "Download and Compile OpenMPI for EMU (singularity) ... "

# Choose between interactive or batch 
echo
echo "Compiling OpenMPI can take a while (~30 min) ... "
echo 
echo "Choose to compile interactively (1) or by batch job (2) ... (1/2)?"
echo "(For option 2, see README_openmpi_setup before proceeding.)"
read fmode 
echo 
echo "Done with user input."

if [[ $fmode -eq 1 ]]; then 

    echo
    echo "----------------------"
    echo "Download and Compiling OpenMPI as a background job ... "

    log_file="${emu_userinterface_dir}/emu_openmpi_setup.log"
    echo "This can take a while (~30 minutes). "
    echo "Progress can be monitored in file " ${log_file}
    echo "  tail ${log_file} "

    ${emu_userinterface_dir}/emu_openmpi_install.sh  > "$log_file" 2>> "$log_file" &

    emu_openmpi_install_pid=$!

    echo "Download and compiling OpenMPI pid is " ${emu_openmpi_install_pid}

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

    check_job ${emu_openmpi_install_pid} "EMU compatible OpenMPI setup" "${log_file}"

else
    echo
    echo "----------------------"
    echo "Download and Compiling OpenMPI in batch job by "
    echo "submitting pbs_openmpi_setup.sh to batch system "

    returndir=$PWD
    cd ${emu_userinterface_dir}
    BATCH_COMMAND ./pbs_openmpi_setup.sh
    cd ${returndir}
fi
echo


    

    
    
