#!/bin/bash -e

umask 022

#=================================
# Shell script for setting up V4r4 Convolution Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Convolution Tool ..."
#echo "    See PUBLICDIR/README_conv "
echo " "

## Set directory names for the tool. 
#echo ${emu_dir} > ./tool_setup_dir
#echo ${emu_input_dir} > ./input_setup_dir

# Set up convolution programs (conv.x, do_conv.x)
/bin/ln -sf ${emu_dir}/emu/exe/conv.x .

## 
#echo " "
#echo '********************************************'
#echo '    Run conv.x to specify convolution.'
#echo '********************************************'
#echo " "
