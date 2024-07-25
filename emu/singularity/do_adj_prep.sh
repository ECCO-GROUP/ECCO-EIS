#!/bin/bash -e
#
# Prepare to run MITgcm adjoint 
#

#=================================
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)

#ln -s ${emu_dir}/namelist/* .
ln -sf ${emu_dir}/emu/emu_input/namelist/* .

if [ -f data_adj ]; then
    mv -f data_adj data
fi

if [ -f data.ecco_adj ]; then
    mv -f data.ecco_adj data.ecco
fi

#=================================
# Ready running flux-forced V4r4 adjoint 
#python3 mkdir_subdir_diags.py
python3 /emu_input_dir/forcing/input_init/tools/mkdir_subdir_diags.py

#ln -s ${emu_dir}/build_ad/mitgcmuv_ad .
