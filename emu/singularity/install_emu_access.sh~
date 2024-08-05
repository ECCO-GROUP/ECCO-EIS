#!/bin/bash -e 
#
# Install shell scripts to run EMU
#

umask 022

echo ""
echo "Installing EMU scripts for running EMU Tools (singularity) ... "

# ----------------------------------------
# Choose and create destination directory 
echo 
echo "Enter destination directory name ... ?"
read useraccessdir

echo 
echo "EMU Scripts destination will be "${useraccessdir}
if [ ! -d ${useraccessdir} ]; then
    mkdir ${useraccessdir}
fi

# Make sure path is absolute
useraccessdir=$(realpath "$useraccessdir")

# ----------------------------------------
# ID path to EMU Singularity image (sif file).

# ..................
# Look for sif in default location

# Get the full path of this script
script_name=$(readlink -f "$0")

# Get emu_dir pathname 
script_dir=$(dirname "$script_name")
singularity_dir=$(dirname "$script_dir")
emu_dir=$(dirname "singularity_dir")

# Check for emu.sif in default location
singularity_image=${emu_dir}/emu.sif

if [[ ! -e "${singularity_image}" ]]; then 

    echo 
    echo "Enter full path to EMU singularity image ... ?"
    read singularity_image

# check file
    if [ ! -e "${singularity_image}" ] || [ ! -x "${singularity_image}" ]; then
	echo 
	echo "File does not exist or is not executable."
	exit 1 
    fi    
fi

# Make sure path is absolute
singularity_image=$(realpath "$singularity_image")

echo 'image_'${singularity_image}  >> ${useraccessdir}/install_emu_access.singularity

echo 
echo "EMU singularity image: ${singularity_image}"

# ----------------------------------------
# Installing scripts from EMU Singularity image 

currentdir=$PWD
cd ${useraccessdir}

/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'                    >> my_commands.sh
echo 'cp -p ${emu_dir}/emu/emu*.sh .'    >> my_commands.sh
echo 'cp -p ${emu_dir}/emu/README*  .'   >> my_commands.sh
echo 'cp -p ${emu_dir}/emu/Guide*.pdf .' >> my_commands.sh
echo 'cp -p ${emu_dir}/emu/misc*.sh .'   >> my_commands.sh
echo 'cp -p ${emu_dir}/emu/misc*.txt .'  >> my_commands.sh
echo 'emu_version="singularity" '        >> my_commands.sh
echo 'cp -p -f ${emu_dir}/emu/${emu_version}/emu_* .'  >> my_commands.sh
echo 'cp -p -f ${emu_dir}/emu/${emu_version}/pbs_* .'  >> my_commands.sh
echo 'cp -p -f ${emu_dir}/emu/${emu_version}/misc_* .' >> my_commands.sh

singularity exec --bind ${useraccessdir}:/inside_out \
    ${singularity_image} /inside_out/my_commands.sh

/bin/rm -f my_commands.sh

ln -sf ${useraccessdir}/emu.sh ${useraccessdir}/emu

# ----------------------------------------
# Setup emu environment variables

./emu_env.sh

cd ${currentdir}

# ----------------------------------------
# Finish 
echo 
echo "install_emu_access.sh (singularity) execution complete. $(date)"


