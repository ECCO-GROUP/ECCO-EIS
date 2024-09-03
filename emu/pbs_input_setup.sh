#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=24:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#PBS -k od

umask 022

#=================================
# PBS script to run emu_input_install_4batch.sh in batch mode 
#=================================

set -e  # Exit immediately if any command fails

#=================================
# Set program specific parameters 
emu_input_dir=EMU_INPUT_DIR
emu_userinterface_dir=PUBLICDIR

Earthdata_username=EARTHDATA_USERNAME
WebDAV_password=WEBDAV_PASSWORD
emu_input=EMU_INPUT

#=================================
# cd to setup_dir and run emu_input_install_4batch.sh 
cd ${emu_userinterface_dir}

./emu_input_install_4batch.sh <<EOF 
${Earthdata_username}
${WebDAV_password}
${emu_input}
EOF


