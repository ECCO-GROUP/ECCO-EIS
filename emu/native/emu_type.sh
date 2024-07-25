#!/bin/bash -e 

echo " "
echo " ****************** "
echo "  This version of EMU has been compiled on host (native) "
echo " ****************** "


if [ ! -f "PUBLICDIR/emu_env.native" ] ; then
    echo " File PUBLICDIR/emu_env.native not found. "
    echo " EMU is not correctly set up. " 
    exit 1 
else
    # Read the file line by line and assign values to variables
    while IFS= read -r line; do
	case $line in
	    emudir_*) emu_dir=${line#image_} ;;
	    emuinputdir_*) emu_input_dir=${line#input_} ;;
	    batch_*) batch_command=${line#batch_} ;;
	    emunproc_*) emu_nproc=${line#emunproc_} ;;
	esac
    done < PUBLICDIR/emu_env.native

    # Make sure environment is correctly set
    check=true
    if [[ ! -e ${emu_dir} ]]; then 
	echo 
	echo " EMU's Programs directory "
	echo ${emu_dir}
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
	echo "Read from file emu_env.native ... "
	echo "   EMU source PARENT directory: ${emu_dir}"
	echo "   EMU Input PARENT directory: ${emu_input_dir}"
	echo "   Command to submit batch job: ${batch_command}"
	echo "   Number of CPU cores used for MITgcm: ${emu_nproc}"
    else
	echo "EMU is not correctly set up. " 
	exit 1
    fi

fi

