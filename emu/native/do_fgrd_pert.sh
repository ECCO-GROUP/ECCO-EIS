#!/bin/bash -e 
#
# Perturb (change) control file and ready running MITgcm 
#

umask 022

#=================================
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)
#ln -sf ${emu_dir}/namelist/* .
ln -sf ${emu_dir}/emu/emu_input/namelist/* .
/bin/rm -f ./data.diagnostics
/bin/rm -f ./data.pkg
/bin/rm -f ./data.ecco
/bin/rm -f ./data

if [ -f data_fgrd ]; then
    mv -f ./data_fgrd ./data
else
    ln -sf ${emu_dir}/emu/data .
fi

ln -sf ${emu_dir}/emu/data.diagnostics .
ln -sf ${emu_dir}/emu/data.pkg_notapes ./data.pkg
ln -sf ${emu_dir}/emu/data.ecco_fgrd ./data.ecco

#=================================
# if nIter0 is not 1, use data.ctrl.noinitctrl in place of data.ctrl 
# so that xx_IC (where IC is etan, salt, theta, uvel, vvel) is not 
# added to initial condition (pickup file).

set +e
# Search for 'nIter0' assignment in the file data 
grep -E '^[[:space:]]*nIter0[[:space:]]*=[[:space:]]*1[[:space:],]*$' data > /dev/null

# Check the exit status of grep and substitute file if nIter0 ne 1
if [[ $? -ne 0 ]]; then
    rm data.ctrl
    cp data.ctrl.noinitctrl data.ctrl
fi
set -e

#=================================
# Perturb (change) control file by fgrd_pert.f
# Perturbation specified in fgrd_pert.nml, created by 
# fgrd_spec.f or equivalent.

ln -sf ${emu_dir}/emu/exe/fgrd_pert.x .

./fgrd_pert.x ${emu_input_dir}/forcing

#=================================
# Ready running flux-forced V4r4
python3 mkdir_subdir_diags.py

#ln -sf ${emu_dir}/build/mitgcmuv .
