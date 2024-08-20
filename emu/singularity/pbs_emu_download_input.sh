#PBS -S /bin/bash
#PBS -l select=1:ncpus=40:model=sky_ele
#PBS -l walltime=24:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea

umask 022

#=================================
# PBS script to run emu_download_input.sh in batch mode 
#=================================

set -e  # Exit immediately if any command fails

#=================================
# Set program specific parameters 
emu_input_dir=EMU_INPUT_DIR
emu_userinterface_dir=PUBLICDIR

Earthdata_username=EARTHDATA_USERNAME
WebDAV_password=WEBDAV_PASSWORD
emu_choice=EMU_CHOICE

#=================================
# cd to setup_dir and run emu_download_input.sh 
cd ${emu_userinterface_dir}

./emu_download_input.sh <<EOF 
${Earthdata_username}
${WebDAV_password}
${emu_input_dir}
${emu_choice}
1
EOF


