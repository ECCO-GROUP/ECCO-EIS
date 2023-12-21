#!/bin/bash
#
# Prepare to run MITgcm adjoint 
#

basedir=SETUPDIR

#=================================
# Over-ride V4 namelist files with EMU's. 
# (integration duration and output precision)

ln -s ${basedir}/namelist/* .

if [ -f data_adj ]; then
    mv -f data_adj data
fi

if [ -f data.ecco_adj ]; then
    mv -f data.ecco_adj data.ecco
fi

#=================================
# Ready running flux-forced V4r4 adjoint 
python3 mkdir_subdir_diags.py

ln -s ${basedir}/build_ad/mitgcmuv_ad .
