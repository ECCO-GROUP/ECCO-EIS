#!/bin/bash 

#=================================
# Shell script for setting up V4r4 Convolution Tool
#=================================

echo " "
echo "... Setting up ECCO V4r4 Convolution Tool ..."
echo "    See PUBLICDIR/README_conv "
echo " "

# Set directory names for the tool. 

setup=SETUPDIR
echo $setup > tool_setup_dir

# Set up convolution programs (conv.x, do_conv.x)
/bin/ln -sf ${setup}/emu/conv.x .

## 
#echo " "
#echo '********************************************'
#echo '    Run conv.x to specify convolution.'
#echo '********************************************'
#echo " "
