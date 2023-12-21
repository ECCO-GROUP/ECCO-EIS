#!/bin/bash
#
# Create link to outside files neede to run flux-forced V4r4
#

basedir=SETUPDIR
inputdir=${basedir}/forcing

# Link outside files 
ln -s ${inputdir}/other/flux-forced/*/* .

ln -s ${inputdir}/input_init/error_weight/ctrl_weight/* .
ln -s ${inputdir}/input_init/* .
ln -s ${inputdir}/input_init/tools/* .

