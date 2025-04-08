#!/bin/bash 

#=================================
# Master shell script for Auxillary EMU routines
#=================================

#=================================

returndir=${PWD}

echo " "
echo " "
echo "************************************"
echo "    EMU Auxillary Tool "
echo "************************************"
echo 
echo " The Auxillary Tool generates examples of what other EMU tools employ as" 
echo " user input files. "
echo " See PUBLICDIR/README_aux "

# Choose Auxillary Tool
echo " "
echo "Choose among the following examples ... "
echo " "
echo "  1) Masks defining objective function [samp, adj, atrb]"
echo "  2) Specify model integration period [msim]" 
echo "  3) Specify model diagnostic output [msim]"
echo "  4) Replace model forcing with its time-mean [msim]"
echo "  5) Replace model initial condition with time-mean state [msim]"
echo "  6) Use end state from another simulation as model initial condition [msim]"
echo " "
echo "Enter choice ... (1-6)?"

read aux_choice

# If not already running, run new EMU 
if [ "$aux_choice" -eq 1 ]; then
    echo "Auxillary Tool (mask)" > emu.lock
    echo "choice is 1) Create mask (running misc_mask.sh)"
    bash PUBLICDIR/misc_mask.sh

elif [ "$aux_choice" -eq 2 ]; then
    echo "Auxillary Tool (integration period)" > emu.lock
    echo "choice is 2) Set integration period (running misc_msim_data.sh)"
    bash PUBLICDIR/misc_msim_data.sh

elif [ "$aux_choice" -eq 3 ]; then
    echo "Auxillary Tool (diagnostic output)" > emu.lock
    echo "choice is 3) Set diagnostic output (running misc_msim_diagnostics.sh)"
    bash PUBLICDIR/misc_msim_diagnostics.sh

elif [ "$aux_choice" -eq 4 ]; then
    echo "Auxillary Tool (time-mean forcing)" > emu.lock
    echo "choice is 4) Replace forcing with its time-mean (running misc_msim_forcing.sh)"
    bash PUBLICDIR/misc_msim_forcing.sh

elif [ "$aux_choice" -eq 5 ]; then
    echo "Auxillary Tool (time-mean initial condition)" > emu.lock
    echo "choice is 5) Replace initial condition with time-mean state (running misc_msim_ic.sh)"
    bash PUBLICDIR/misc_msim_ic.sh

elif [ "$aux_choice" -eq 6 ]; then
    echo "Auxillary Tool (initial condition from end of another simulation)" > emu.lock
    echo "choice is 6) Use end state from another simulation as initial condition (running misc_msim_pickup.sh)"
    bash PUBLICDIR/misc_msim_pickup.sh

else
    echo "Invalid choice for Auxillary Tool ... " $aux_choice
fi
cd ${returndir}
rm -f emu.lock  


