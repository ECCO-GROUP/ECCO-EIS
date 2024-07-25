#!/bin/bash -e 
#
# Set variable pathnames and environment 
#

umask 022

# ----------------------------------------
echo 
echo "Setting full pathnames to EMU scripts (singularity) ... "

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

# Read EMU Singularity image set from install_emu_access.sh
# check file
if [ ! -e install_emu_access.singularity ] ; then
    echo
    echo "File install_emu_access.singularity does not exist." 
    echo "Re-run install_emu_access.sh" 
    exit 1 
fi    

# Read the file line by line and assign values to variables
while IFS= read -r line; do
    case $line in
	image_*) singularity_image=${line#image_} ;;
    esac
done < install_emu_access.singularity


# --------------------------------------------------
# Specify rest 
if [ ! -f emu_env.singularity ] ; then

# --------------------------------------------------
# Record EMU Singularity image 
    echo "image_${singularity_image}"  > emu_env.singularity

    echo 
    echo "EMU singularity image: ${singularity_image}"
    
    emu_dir=$(dirname "${singularity_image}")

# --------------------------------------------------
# Set EMU Input directory (output of emu_download_input.sh) 
    echo 
    echo "Is EMU Input downloaded by emu_download_input.sh located in the same directory as the image at"
    echo "${emu_dir}"
    echo 
    echo "Press ENTER key if the same or enter an alternate directory if otherwise ... ?"
    read emu_input_dir

    if [[ -z ${emu_input_dir} ]]; then
	emu_input_dir=${emu_dir}
    fi

# Make sure EMU Input exists (check with directory forcing_weekly)
    forcingdir=${emu_input_dir}/forcing/other/flux-forced/forcing_weekly
    if [ ! -d "${forcingdir}" ]; then 
	echo 
	echo "EMU Input Files not found in ${emu_input_dir}."
	echo "Make sure to run emu_download_input.sh to download EMU Input Files."
#	/bin/rm emu_env.singularity
#	exit 1
    fi

# Make sure path is absolute
    emu_input_dir=$(realpath "${emu_input_dir}")

    echo "input_${emu_input_dir}" >> ./emu_env.singularity

    echo 
    echo "EMU Input Files directory (where directory forcing etc are located):"
    echo "${emu_input_dir}"

    echo $emu_input_dir > ./input_setup_dir

# --------------------------------------------------
# EMU image compatible native mpiexec 
    echo 
    echo "Enter the pathname for EMU compatible native mpiexec ... ?"
    read native_mpiexec
#    if [ ! -e "${native_mpiexec}" ] ; then
#	echo ${native_mpiexec}" does not exist." 
#	/bin/rm emu_env.singularity
#	exit 1 
#    fi    

# Make sure path is absolute
    if [[ ! "${native_mpiexec}" =~ ^/ ]]; then
	native_mpiexec=$(realpath "${native_mpiexec}")
    fi

    echo "mpiexec_${native_mpiexec}"   >> emu_env.singularity

    echo 
    echo "EMU compatible mpiexec: ${native_mpiexec}"
    
# --------------------------------------------------
# Command to submit batch job; e.g., qsub for PBS 
    echo "!!! Need to specify native command to submit batch jobs (e.g., qsub) !!! " 
    echo "Note: EMU provides job scripts for the PBS system at"
    echo "      NASA Ames that uses qsub as the command to "
    echo "      submit the scripts. In addition to specifying" 
    echo "      this command here, the job scripts (pbs_*.sh)" 
    echo "      in this EMU user access directory likely needs"
    echo "      to be modified for them to work properly on"
    echo "      other systems."
    echo "Enter native command to submit batch job (e.g., qsub) ... ?" 
    echo "(Enter bash for running all EMU tools interactively.)" 
    read batch_command 
    echo "batch_${batch_command}"  >> emu_env.singularity
    echo "Command to submit batch job: ${batch_command}"
    echo " " 

# --------------------------------------------------
# Set number of nodes to use for MITgcm

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
   echo '       echo "${emu_dir}/emu/native/emu_compile_mdl.sh" '  >> my_commands.sh
   echo '	exit 1 '  >> my_commands.sh
   echo 'fi '  >> my_commands.sh

# Print out n_exe for use outside singularity image 
   echo 'rm -f ./n_exe.txt '                >> my_commands.sh
   echo 'for item in "${n_exe[@]}"; do '    >> my_commands.sh
   echo '    echo "$item" >> ./n_exe.txt '  >> my_commands.sh
   echo 'done '                             >> my_commands.sh

   singularity exec --bind ${useraccessdir}:/inside_out \
       ${singularity_image} /inside_out/my_commands.sh

# Search available executables (compiled by native/emu_compile_mdl.sh)
   mapfile -t n_exe < ./n_exe.txt

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
    echo "emunproc_${emu_nproc}"  >> ./emu_env.singularity
    echo "Number of CPU cores to be used for MITgcm: ${emu_nproc}"
    echo " " 

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
    done < emu_env.singularity

    # Print the values of the variables
    echo "Read from file emu_env.singularity ... "
    echo "   EMU singularity image: ${singularity_image}"
    echo "   EMU input directory: ${emu_input_dir}"
    echo "   EMU compatible mpiexec: ${native_mpiexec}"
    echo "   Command to submit batch job: ${batch_command}"
    echo "   Number of CPU cores used for MITgcm: ${emu_nproc}"
fi

# --------------------------------------------------
# Apply substitution, excluding the present file 
current_script="$(basename "$0")"
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_DIR|/ecco|g" {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|SINGULARITY_IMAGE|${singularity_image}|g"  {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_INPUT_DIR|${emu_input_dir}|g"  {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|NATIVE_MPIEXEC|${native_mpiexec}|g"  {} +
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|BATCH_COMMAND|${batch_command}|g" {} +

# Set nproc in PBS scripts 
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|EMU_NPROC|${emu_nproc}|g" {} +

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                    >> my_commands.sh
echo "head -n 1 \${emu_dir}/emu/emu_input/nproc/${emu_nproc}/PBS_nodes"   >> my_commands.sh
choose_nodes=$(singularity exec --bind ${useraccessdir}:/inside_out \
       ${singularity_image} /inside_out/my_commands.sh )
find . -name '*.sh' ! -name "$current_script" -exec sed -i -e "s|CHOOSE_NODES|${choose_nodes}|g" {} +

# Set timing information of MITgcm used for PBS scripts 
   /bin/rm -f my_commands.sh
   echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
   echo "cd /inside_out"                    >> my_commands.sh

   echo "cp -f \${emu_dir}/emu/emu_input/nproc/${emu_nproc}/mitgcm_timing.nml ." >> my_commands.sh
   echo "\${emu_dir}/emu/exe/check_timing.x  " >> my_commands.sh
   
   singularity exec --bind ${useraccessdir}:/inside_out \
       ${singularity_image} /inside_out/my_commands.sh

exit 0



