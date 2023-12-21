#!/bin/bash 

#=================================
# Master shell script for EMU
#=================================

#returndir=${PWD}
#
#if [ ! -d emu_temp ]; then
#    echo "Creating EMU temporary directory ... "
#    mkdir emutemp
#fi
#cd emutemp

echo " "
echo "ECCO Modeling Utilities (EMU) ..."
echo "See PUBLICDIR/README "
echo " "

# Choose Tool
echo "Choose among the following tools ... "
echo " "
echo "  1) Sampling Tool (samp); Extracts time-series from model output."
echo "  2) Perturbation Tool (pert); Computes forward gradient."
echo "  3) Adjoint Tool (adj); Computes adjoint gradient."
echo "  4) Convolution Tool (conv); Computes adjoint gradient decomposition."
echo "  5) Tracer Tool (trc); Computes passive tracer integration."
echo "  6) Budget Tool (budg); Extracts budget time-series from model output."
echo " "
echo "Enter choice ... (1-6)?"

read emu_choice

# Check to see if emu is already running in current directory
if [ ! -f "./emu.lock" ]; then 

# If not already running, run new EMU 
if [ "$emu_choice" -eq 1 ]; then
    echo "Sampling Tool" > emu.lock
    echo "choice is 1) Sampling (samp)"
    echo "See PUBLICDIR/README_samp"
    PUBLICDIR/emu_samp.sh
elif [ "$emu_choice" -eq 2 ]; then
    echo "Perturbation Tool" > emu.lock
    echo "choice is 2) Perturbation (pert)"
    echo "See PUBLICDIR/README_pert"
    cp -f PUBLICDIR/pbs_pert.sh pbs_pert.sh_orig
    PUBLICDIR/emu_pert.sh
elif [ "$emu_choice" -eq 3 ]; then
    echo "Adjoint Tool" > emu.lock
    echo "choice is 3) Adjoint (adj)" 
    echo "See PUBLICDIR/README_adj"
    cp -f PUBLICDIR/pbs_adj.sh pbs_adj.sh_orig
    PUBLICDIR/emu_adj.sh
elif [ "$emu_choice" -eq 4 ]; then
    echo "Convolution Tool" > emu.lock
    echo "choice is 4) Convolution (conv)" 
    echo "See PUBLICDIR/README_conv"
    cp -f PUBLICDIR/pbs_conv.sh pbs_conv.sh_orig
    PUBLICDIR/emu_conv.sh
elif [ "$emu_choice" -eq 5 ]; then
    echo "Tracer Tool" > emu.lock
    echo "choice is 5) Tracer (trc)" 
    echo "See PUBLICDIR/README_trc"
    cp -f PUBLICDIR/pbs_trc.sh . 
    PUBLICDIR/emu_trc.sh
elif [ "$emu_choice" -eq 6 ]; then
    echo "Budget Tool" > emu.lock
    echo "choice is 6) Budget (budg)" 
    echo "See PUBLICDIR/README_budg"
    PUBLICDIR/emu_budg.sh
else
    echo "Invalid choice ... " $emu_choice
fi
rm -f ./emu.lock  

else  
# Case when EMU is already running in current directory.
    echo "*** CONFLICT ***"
    read -r tdum < ./emu.lock
    echo "EMU " $tdum " is already running in this directory."
    echo "Wait until it finishes or run EMU in another directory." 
    echo "(or delete file emu.lock and rerun EMU if previous run was aborted.)" 
fi

#cd ${returndir}
