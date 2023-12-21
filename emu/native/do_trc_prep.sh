#!/bin/bash
#
# Prepare to run offline tracer integration 
#

basedir=SETUPDIR

#=================================
# Link all files needed to run flux-forced V4r4 
ln -s ${basedir}/emu/emu_input/namelist_offline_ptracer/* . 

#
inputdir=${basedir}/forcing

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

#=================================
# Over-ride runtime namelist files. 
# (data_trc integration time set by trc.f)
mv -f data_trc data

#=================================
# Run flux-forced V4r4
python3 mkdir_subdir_diags.py


