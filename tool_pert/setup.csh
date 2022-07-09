#!/bin/tcsh

#=================================
# Shell script for setting up V4r4 perturbation tool
#=================================

echo "... Setting up ECCO V4r4 Perturbation Tool ..."
echo "    See PUBLICDIR/README_pert "

# Set directory names for the tool. 
set userdir=`pwd`
set tooldir = SETUPDIR

# Set up perturbation specifying program (pert_nml.x)
cp -p ${tooldir}/tool_pert/pert_nml.x .
echo $tooldir > pert_nml.tooldir

# Set up data namelist file to be used by MITgcm (data) 
#
# This data namelist file (data.18mo) only runs the model for
# 18-months.  Comment out the following line to use the default data
# file or edit the copied file to meet your needs. See README_pert
# above for details.
#
cp -p ${tooldir}/tool_pert/data.18mo data 

# Set up Tool's PBS script (tool_pert.csh) 
#
# This PBS script (tool_pert.csh) runs only up to 2-hours walltime on
# the devel queue. Revise walltime and queue as needed. See
# README_pert above for details.
#
cp ${tooldir}/tool_pert/tool_pert.csh .
sed -i -e "s|YOURDIR|${userdir}|g" tool_pert.csh

exit
