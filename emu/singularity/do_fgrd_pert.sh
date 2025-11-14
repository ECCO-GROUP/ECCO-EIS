#!/bin/bash -e 
#
# Perturb (change) control file and ready running MITgcm 
#

#=================================
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)
#ln -sf ${emu_dir}/namelist/* .
ln -sf ${emu_dir}/emu/emu_input/namelist/* .
/bin/rm -f data.diagnostics
/bin/rm -f data.pkg
/bin/rm -f data.ecco
/bin/rm -f data

if [ -f data_fgrd ]; then
    mv -f data_fgrd data
else
    ln -sf ${emu_dir}/emu/data .
fi

ln -sf ${emu_dir}/emu/data.diagnostics .
ln -sf ${emu_dir}/emu/data.pkg_notapes data.pkg
ln -sf ${emu_dir}/emu/data.ecco_fgrd data.ecco

#=================================
# Perturb (change) control file by fgrd_pert.f
# Perturbation specified in fgrd_pert.nml, created by 
# fgrd_spec.f or equivalent.

ln -sf ${emu_dir}/emu/exe/fgrd_pert.x .

./fgrd_pert.x /emu_input_dir/forcing

#=================================
# Ready running flux-forced V4r4
#python3 mkdir_subdir_diags.py
python3 /emu_input_dir/forcing/input_init/tools/mkdir_subdir_diags.py

#ln -sf ${emu_dir}/build/mitgcmuv .
