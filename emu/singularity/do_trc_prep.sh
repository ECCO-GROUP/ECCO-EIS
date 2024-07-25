#!/bin/bash -e
#
# Prepare to run offline tracer integration 
#

#=================================
# Link all files needed to run flux-forced V4r4 
ln -sf ${emu_dir}/emu/emu_input/namelist_offline_ptracer/* . 

#
ln -sf /emu_input_dir/forcing/input_init/error_weight/ctrl_weight/* .
ln -sf /emu_input_dir/forcing/input_init/* .
ln -sf /emu_input_dir/forcing/input_init/tools/* .

#=================================
# Over-ride runtime namelist files. 
# (data_trc integration time set by trc.f)
mv -f ./data_trc ./data

#=================================
# Run flux-forced V4r4
#python3 mkdir_subdir_diags.py
python3 /emu_input_dir/forcing/input_init/tools/mkdir_subdir_diags.py


