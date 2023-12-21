#!/bin/bash
#
# Set variable pathnames and environment 
#

echo "Setting full pathnames to EMU scripts ... "

useraccessdir=${PWD}

sed -i -e "s|PUBLICDIR|${useraccessdir}|g" *.*

# --------------------------------------------------
# Specify variable names 

if [ ! -f emu_env.native ] ; then

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
    echo 'batch_'${batch_command}  > emu_env.native
    echo "Command to submit batch job: ${batch_command}"
    echo " " 

# ECCO input (forcing etc)    
    native_setup=SETUPDIR
    echo 'native_'${native_setup} >> emu_env.native 
    echo "Native ECCO flux-forced model directory: ${native_setup}"
    echo ""

else
    # Read the file line by line and assign values to variables
    while IFS= read -r line; do
	case $line in
	    batch_*) batch_command=${line#batch_} ;;
	    native_*) native_setup=${line#native_} ;;
	esac
    done < emu_env.native 

    # Print the values of the variables
    echo "Read from file emu_env.native ... "
    echo "   Command to submit batch job: ${batch_command}"
    echo "   Native ECCO flux-forced model directory: ${native_setup}"
fi

sed -i -e "s|BATCH_COMMAND|${batch_command}|g" *.*sh
sed -i -e "s|NATIVE_SETUP|${native_setup}|g" *.*sh




