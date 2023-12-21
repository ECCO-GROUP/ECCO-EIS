#!/bin/bash
#
# Perturb (change) control file and ready running MITgcm 
#

basedir=SETUPDIR

#=================================
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)
ln -s ${basedir}/namelist/* .
/bin/rm -f data.diagnostics
/bin/rm -f data.pkg
/bin/rm -f data.ecco
/bin/rm -f data

if [ -f data_pert ]; then
    mv -f data_pert data
else
    ln -s ${basedir}/emu/data .
fi

ln -s ${basedir}/emu/data.diagnostics .
ln -s ${basedir}/emu/data.pkg .
ln -s ${basedir}/emu/data.ecco_pert data.ecco

#=================================
# Perturb (change) control file by pert_xx.f
# Perturbation specified in pert_xx.nml, created by 
# pert.f or equivalent.

ln -s ${basedir}/emu/pert_xx.x .

pert_xx.x ${basedir}/forcing

#=================================
# Ready running flux-forced V4r4
python3 mkdir_subdir_diags.py

ln -s ${basedir}/build/mitgcmuv .
