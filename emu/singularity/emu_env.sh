#!/bin/bash
#
# Set variable pathnames and environment 
#

echo "Setting full pathnames to EMU scripts ... "

useraccessdir=${PWD}

sed -i -e "s|PUBLICDIR|${useraccessdir}|g" *.*

# --------------------------------------------------
# Specify variable names 

if [ ! -f emu_env.singularity ] ; then

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
    read batch_command 
    echo 'batch_'${batch_command}  > emu_env.singularity
    echo "Command to submit batch job: ${batch_command}"
    echo " " 

# EMU Singularity image 
    echo "Enter EMU singularity image ... ?"
    read singularity_image
    echo 'image_'${singularity_image}  >> emu_env.singularity
    echo "EMU singularity image: ${singularity_image}"
    echo ""

# Native singularity command 
    echo "Enter full pathname for native singularity command ... ?"
    read native_singularity
    echo 'singularity_'${native_singularity} >> emu_env.singularity
    echo "Singularty: ${native_singularity}"
    echo ""

# EMU image compatible native mpiexec 
    echo "Enter full pathname for EMU compatible native mpiexec ... ?"
    read native_mpiexec
    echo 'mpiexec_'${native_mpiexec}    >> emu_env.singularity
    echo "EMU compatible mpiexec: ${native_mpiexec}"
    echo ""
    
# ECCO input (forcing etc)    
    echo "Enter native ECCO flux-forced model directory ... ?"
    read native_setup
    echo 'native_'${native_setup} >> emu_env.singularity 
    echo "Native ECCO flux-forced model directory: ${native_setup}"
    echo ""

else
    # Read the file line by line and assign values to variables
    while IFS= read -r line; do
	case $line in
	    batch_*) batch_command=${line#batch_} ;;
	    image_*) singularity_image=${line#image_} ;;
	    native_*) native_setup=${line#native_} ;;
	    singularity_*) native_singularity=${line#singularity_} ;;
	    mpiexec_*) native_mpiexec=${line#mpiexec_} ;;
	esac
    done < emu_env.singularity

    # Print the values of the variables
    echo "Read from file emu_env.singularity ... "
    echo "   Command to submit batch job: ${batch_command}"
    echo "   EMU singularity image: ${singularity_image}"
    echo "   Singularty: ${native_singularity}"
    echo "   EMU compatible mpiexec: ${native_mpiexec}"
    echo "   Native ECCO flux-forced model directory: ${native_setup}"
fi

sed -i -e "s|BATCH_COMMAND|${batch_command}|g" *.*sh
sed -i -e "s|SINGULARITY_IMAGE|${singularity_image}|g" *.*sh
sed -i -e "s|NATIVE_SINGULARITY|${native_singularity}|g" *.*sh
sed -i -e "s|NATIVE_MPIEXEC|${native_mpiexec}|g" *.*sh
sed -i -e "s|NATIVE_SETUP|${native_setup}|g" *.*sh




