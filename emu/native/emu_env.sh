#!/bin/bash -e
#
# Set variable pathnames and environment 
#

umask 022

# ----------------------------------------
echo 
echo "Setting full pathnames to EMU scripts (native) ... "

# ----------------------------------------
# ID path to EMU useraccess files 

# Get the full path of this script
script_path=$(readlink -f "$0")

# Get the directory containing the script
useraccessdir=$(dirname "$script_path")

current_script="$(basename "$0")"
find . -type f -name '*.*' ! -name "$current_script" -exec sed -i -e 's|PUBLICDIR|'"${useraccessdir}"'|g'  {} +
sed -i -e "s|PUBLICDIR|${useraccessdir}|g" ./README*

# --------------------------------------------------
# Specify variable names 

if [ ! -f ./emu_env.native ] ; then

# Set EMU directory location (parent directory of directory emu) 
    emu_dir=BASE_DIR

# Search available executables (compiled by native/emu_compile_mdl.sh)
    exe_dir=${emu_dir}/emu/exe/nproc
    n_exe_raw=($(find ${exe_dir} -maxdepth 1 -type d -name "[0-9]*" -printf "%f\n"))
    n_exe=($(for i in "${n_exe_raw[@]}"; do echo $i; done | sort -n))
    if [ ${#n_exe[@]} -eq 0 ]; then
	echo 
	echo "No executable for MITgcm found in " ${exe_dir}
	echo "Compile MITgcm before installing EMU User Access files with " 
	echo ${emu_dir}"/emu/native/emu_compile_mdl.sh" 
	exit 1
    fi

# Continue setting EMU directory location 
    echo 'emudir_'${emu_dir} > ./emu_env.native 
    echo 
    echo "EMU source PARENT directory (where directory emu is located):"
    echo "${emu_dir}"

    echo $emu_dir > ./tool_setup_dir

# Set EMU Input directory (output of emu_download_input.sh) 
    echo 
    echo "Is EMU Input downloaded by emu_download_input.sh also located in this directory?"
    echo "${emu_dir}"
    echo 
    echo "Press ENTER key if the same or enter an alternate directory if otherwise ... ?"
    read emu_input_dir

    if [[ -z ${emu_input_dir} ]]; then
	emu_input_dir=${emu_dir}
    fi

# Make sure EMU Input exists (check with directory forcing)
    forcingdir=${emu_input_dir}/forcing/other/flux-forced/forcing
    if [ ! -d "${forcingdir}" ]; then 
	echo 
	echo "EMU input not found in ${emu_input_dir}."
	echo "Make sure to run emu_download_input.sh to download EMU Input Files."
#	/bin/rm emu_env.native
#	exit 1
    fi

# Make sure path is absolute
    emu_input_dir=$(realpath "${emu_input_dir}")

    echo 'emuinputdir_'${emu_input_dir} >> ./emu_env.native 

    echo 
    echo "EMU Input PARENT directory (where directory forcing etc are located):"
    echo "${emu_input_dir}"

    echo $emu_input_dir > ./input_setup_dir

# Make sure EMU Input exists (check with directory forcing_weekly)
    forcingdir=${emu_input_dir}/forcing/other/flux-forced/forcing_weekly
    if [ ! -d "${forcingdir}" ]; then 
	echo 
	echo "EMU Input Files not found in ${emu_input_dir}."
	echo "Make sure to run emu_download_input.sh to download EMU Input Files."
#	/bin/rm emu_env.singularity
#	exit 1
    fi

# Command to submit batch job; e.g., qsub for PBS 
    echo "!!! Need to specify native command to submit batch jobs (e.g., qsub) !!! " 
    echo "Note: EMU provides job scripts for the PBS system at"
    echo "      NASA Ames that uses qsub as the command to "
    echo "      submit the scripts. In addition to specifying" 
    echo "      this command here, the job scripts (pbs_*.sh)" 
    echo "      in this EMU user access directory likely needs"
    echo "      to be modified for them to work properly in"
    echo "      case of other batch job scheduling systems."
    echo "Enter native command to submit batch job (e.g., qsub) ... ?" 
    echo "(Enter bash for running all EMU tools interactively.)" 
    read batch_command 
    echo 'batch_'${batch_command}  >> ./emu_env.native
    echo "Command to submit batch job: ${batch_command}"
    echo " " 

# Set number of nodes to use for MITgcm

# Search available executables (compiled by native/emu_compile_mdl.sh)
    if [ ${#n_exe[@]} -eq 1 ]; then
	emu_nproc="${n_exe[0]}"
    else
	echo "Enter number of CPU cores (nproc) to use for MITgcm employed by EMU."
	echo "Available options compiled by emu_compile_mdl.sh are ... " 
	for nproc in "${n_exe[@]}"; do
	    echo "$nproc"
	done
	echo " "
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
	if [ "$found" = false ]; then
	    echo "Invalid choice for nproc ... " $emu_nproc
	    exit 1
	fi
    fi
    echo 'emunproc_'${emu_nproc}  >> ./emu_env.native
    echo "Number of CPU cores to be used for MITgcm: ${emu_nproc}"
    echo " " 

else
    # Read the file line by line and assign values to variables
    while IFS= read -r line; do
	case $line in
	    emudir_*) emu_dir=${line#emudir_} ;;
	    emuinputdir_*) emu_input_dir=${line#emuinputdir_} ;;
	    batch_*) batch_command=${line#batch_} ;;
	    emunproc_*) emu_nproc=${line#emunproc_} ;;
	esac
    done < ./emu_env.native 

    # Print the values of the variables
    echo "Read from file emu_env.native ... "
    echo "   EMU source PARENT directory: ${emu_dir}"
    echo "   EMU Input PARENT directory: ${emu_input_dir}"
    echo "   Command to submit batch job: ${batch_command}"
    echo "   Number of CPU cores used for MITgcm: ${emu_nproc}"
fi


# --------------------------------------------------
# Apply substitution, excluding the present file
current_script="$(basename "$0")"
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_DIR|${emu_dir}|g" {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_INPUT_DIR|${emu_input_dir}|g" {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|BATCH_COMMAND|${batch_command}|g" {} +

# Set nproc in PBS scripts 
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_NPROC|${emu_nproc}|g" {} +
choose_nodes=$(head -n 1 ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/PBS_nodes)
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|CHOOSE_NODES|${choose_nodes}|g" {} +

# Set timing information of MITgcm used for PBS scripts 
cp -f ${emu_dir}/emu/emu_input/nproc/${emu_nproc}/mitgcm_timing.nml .
${emu_dir}/emu/exe/check_timing.x 

exit 0

