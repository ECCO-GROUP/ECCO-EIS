#!/bin/bash -e 

echo " "
echo " ****************** "
echo "  This version of EMU is implemented in Singularity "
echo " ****************** "

# Check availablity of singularity 
if ! command -v singularity &> /dev/null; then
    echo 
    echo "**********************"
    echo " ABORT: Command singularity not found."
    exit 1
fi

if [ ! -f "PUBLICDIR/emu_env.singularity" ] ; then
    echo 
    echo "**********************"
    echo " ABORT: File PUBLICDIR/emu_env.singularity not found. "
    echo " EMU is not correctly set up. " 
    exit 1 
else
    # Read the file line by line and assign values to variables
    while IFS= read -r line; do
	case $line in
	    image_*) singularity_image=${line#image_} ;;
	    input_*) emu_input_dir=${line#input_} ;;
	    mpiexec_*) native_mpiexec=${line#mpiexec_} ;;
	    batch_*) batch_command=${line#batch_} ;;
	    emunproc_*) emu_nproc=${line#emunproc_} ;;
	esac
    done < PUBLICDIR/emu_env.singularity

    # Make sure environment is correctly set
    check=true
    if [[ ! -e ${singularity_image} ]]; then 
	echo 
	echo " Singularity image "
	echo ${singularity_image}
	echo " not found. "
	check=false
    fi

    if [[ ! -d ${emu_input_dir} ]]; then 
	echo 
	echo " EMU Input Files directory "
	echo ${emu_input_dir}
	echo " not found. "
	check=false
    fi

    if [[ ! -e ${native_mpiexec} ]]; then 
	echo 
	echo " EMU compatible mpiexec "
	echo ${native_mpiexec}
	echo " not found. "
	echo " Run PUBLICDIR/emu_openmpi_setup.sh"
	echo " to install EMU compatible OpenMPI." 
	check=false
    fi

    if ! command -v ${batch_command} >/dev/null 2>&1; then
	echo 
	echo " Script command "
	echo ${batch_command}
	echo " does not exist. "
	check=false
    fi

    echo
    if [[ "$check" == "true" ]]; then 
	# Print the values of the variables
	echo "Read from file emu_env.singularity ... "
	echo "   EMU singularity image: ${singularity_image}"
	echo "   EMU input directory: ${emu_input_dir}"
	echo "   EMU compatible mpiexec: ${native_mpiexec}"
	echo "   Command to submit batch job: ${batch_command}"
	echo "   Number of CPU cores used for MITgcm: ${emu_nproc}"
    else
	echo
	echo "EMU is not correctly set up. " 
	exit 1
    fi

fi

