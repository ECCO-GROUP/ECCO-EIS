#!/bin/bash -e 
#
# Install shell scripts to run EMU
#

umask 022

echo ""
echo "Installing EMU scripts for running EMU Tools ... "

# ----------------------------------------
# Choose and create destination directory 
echo ""
echo "Enter destination directory name ... ?"
read useraccessdir

echo "EMU Scripts destination will be "${useraccessdir}
if [ ! -d ${useraccessdir} ]; then
    mkdir ${useraccessdir}
fi

# ----------------------------------------
# Choose between native or singularity version of the scripts 
echo ""
echo "Enter native or singularity ... (1/2)?"
read native_or_singularity
if [ ${native_or_singularity} -eq 2 ]; then
    export emu_version='singularity'
    echo "Installing Singularity version ... "

# ID path to EMU Singularity image (sif file).
    echo "Enter full path to EMU singularity image (sif file) ... ?"
    read singularity_image
# check file
    if [ ! -e "${singularity_image}" ] || [ ! -x "${singularity_image}" ]; then
	echo "File does not exist or is not executable."
	exit 1 
    fi    

    echo 'image_'${singularity_image}  >> ${useraccessdir}/emu_env.singularity
    echo "EMU singularity image: ${singularity_image}"
    echo ""

# Installing scripts
    /bin/rm -f my_commands.sh
    echo '#!/bin/bash' > my_commands.sh && chmod +x my_commands.sh
    echo 'cd /inside_out'               >> my_commands.sh
    echo 'cp -p ${emu_dir}/emu/emu*.*sh /emu_outside' >> my_commands.sh
    echo 'cp -p ${emu_dir}/emu/README*  /emu_outside' >> my_commands.sh
    echo 'cp -p ${emu_dir}/emu/Guide*.pdf /emu_outside' >> my_commands.sh

    echo 'cp -p -f ${emu_dir}/emu/${emu_version}/emu* /emu_outside' >> my_commands.sh
    echo 'cp -p -f ${emu_dir}/emu/${emu_version}/pbs* /emu_outside' >> my_commands.sh
    echo 'cp -p -f ${emu_dir}/emu/${emu_version}/misc* /emu_outside' >> my_commands.sh

    ${native_singularity} exec --bind ${useraccessdir}:/emu_outside --bind ${PWD}:/inside_out \
	${singularity_image} /inside_out/my_commands.sh

    ln -sf ${useraccessdir}/emu.sh ${useraccessdir}/emu

else
    export emu_version='native'
    echo "Installing Native version ... "

# ID path to EMU tools
# Get the full path of this script
    script_path=$(readlink -f "$0")
# Get the directory containing the script
    emudir=$(dirname "$script_path")
# Get the parent directory of emudir
    basedir=$(dirname "$emudir")

# Installing scripts
    cp -p ${basedir}/emu/emu*.*sh ${useraccessdir}
    ln -sf ${useraccessdir}/emu.sh ${useraccessdir}/emu
    cp -p ${basedir}/emu/README* ${useraccessdir}
    cp -p ${basedir}/emu/Guide*.pdf ${useraccessdir}

    cp -p -f ${basedir}/emu/${emu_version}/emu* ${useraccessdir}
    cp -p -f ${basedir}/emu/${emu_version}/pbs* ${useraccessdir}
    cp -p -f ${basedir}/emu/${emu_version}/misc* ${useraccessdir}

fi

# ----------------------------------------
# Setup emu environment variables
currentdir=$PWD
cd ${useraccessdir}

if [ "${emu_version}" = 'native' ]; then
    sed -i -e "s|BASE_DIR|${basedir}|g" ./emu_env.sh
fi

./emu_env.sh

cd ${currentdir}

# ----------------------------------------
# Finish 
echo ""
echo "Done ... install_access.sh"
echo ""


