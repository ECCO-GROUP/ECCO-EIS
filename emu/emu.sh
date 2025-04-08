#!/bin/bash 

#=================================
# Master shell script for EMU
#=================================

umask 022

# ----------------------
# Set EMU directories
export emu_dir=EMU_DIR
export emu_input_dir=EMU_INPUT_DIR

# Set directory names for the tool. 
echo ${emu_dir} > ./tool_setup_dir
echo ${emu_input_dir} > ./input_setup_dir

# Make sure PATH includes current directory. 
if [[ ":$PATH:" != *":.:"* ]]; then
    # Add current directory to the PATH
    export PATH="$PATH:."
fi

# ----------------------
# Make sure PWD is not where this script is (emu_userinterface_dir)
emu_userinterface_dir=PUBLICDIR
#script_path=$(readlink -f "$0")
#script_dir=$(dirname "$script_path")

if [[ "$PWD" == "$emu_userinterface_dir" ]] || 
   [[ "$PWD" == "$emu_dir" ]] ||
   [[ "$PWD" == "$emu_input_dir" ]] ; then
    echo 
    echo "***************************************"
    echo " EMU cannot be run from within EMU's directories; "
    echo "   User Interface: ${emu_userinterface_dir}"
    echo "   Programs: ${emu_dir}"
    echo "   Input Files: ${emu_input_dir} "
    echo
    echo " For example, pwd = $emu_userinterface_dir  " 
    echo " is not allowed when running EMU. Change directories and try again;" 
    echo "   e.g., cd ~/ "
    echo "         ${emu_userinterface_dir}/emu "
    echo "***************************************"
    echo 
    exit 
fi

# ----------------------
# Echo type of EMU implementation (emu_type.sh)
if [ -e "PUBLICDIR/emu_type.sh" ]; then
    bash PUBLICDIR/emu_type.sh
fi

#=================================

returndir=${PWD}

echo " "
echo " ECCO Modeling Utilities (EMU) Version 1.1a ... "
echo " See PUBLICDIR/README "

# echo emu_note.sh
if [ -e "PUBLICDIR/emu_note.sh" ]; then
    bash PUBLICDIR/emu_note.sh
fi

# Choose Tool
echo " "
echo "Choose among the following tools ... "
echo " "
echo "  1) Sampling (samp); Evaluates state time-series from model output."
echo "  2) Forward Gradient (fgrd); Computes model's forward gradient."
echo "  3) Adjoint (adj); Computes model's adjoint gradient."
echo "  4) Convolution (conv); Evaluates adjoint gradient decomposition."
echo "  5) Tracer (trc); Computes passive tracer evolution."
echo "  6) Budget (budg); Evaluates budget time-series from model output."
echo "  7) Modified Simulation (msim); Re-runs model with modified input."
echo "  8) Attribution (atrb); Evaluates state time-series by control type."
echo "  9) Auxillary (aux); Generate example user input files for other EMU tools."
echo " "
echo "Enter choice ... (1-9)?"

read emu_choice

# Check to see if emu is already running in current directory
if [ ! -f "emu.lock" ]; then 

# If not already running, run new EMU 
if [ "$emu_choice" -eq 1 ]; then
    echo "Sampling Tool" > emu.lock
    echo "choice is 1) Sampling Tool (samp)"
    echo "See PUBLICDIR/README_samp"
    bash PUBLICDIR/emu_samp.sh

elif [ "$emu_choice" -eq 2 ]; then
    echo "Forward Gradient Tool" > emu.lock
    echo "choice is 2) Forward Gradient Tool (fgrd)"
    echo "See PUBLICDIR/README_fgrd"
    cp -f PUBLICDIR/pbs_fgrd.sh pbs_fgrd.sh_orig
    bash PUBLICDIR/emu_fgrd.sh

elif [ "$emu_choice" -eq 3 ]; then
    echo "Adjoint Tool" > emu.lock
    echo "choice is 3) Adjoint Tool (adj)" 
    echo "See PUBLICDIR/README_adj"
    cp -f PUBLICDIR/pbs_adj.sh pbs_adj.sh_orig
    bash PUBLICDIR/emu_adj.sh

elif [ "$emu_choice" -eq 4 ]; then
    echo "Convolution Tool" > emu.lock
    echo "choice is 4) Convolution Tool (conv)" 
    echo "See PUBLICDIR/README_conv"
    cp -f PUBLICDIR/pbs_conv.sh pbs_conv.sh_orig
    bash PUBLICDIR/emu_conv.sh

elif [ "$emu_choice" -eq 5 ]; then
    echo "Tracer Tool" > emu.lock
    echo "choice is 5) Tracer Tool (trc)" 
    echo "See PUBLICDIR/README_trc"
    cp -f PUBLICDIR/pbs_trc.sh . 
    bash PUBLICDIR/emu_trc.sh

elif [ "$emu_choice" -eq 6 ]; then
    echo "Budget Tool" > emu.lock
    echo "choice is 6) Budget Tool (budg)" 
    echo "See PUBLICDIR/README_budg"
    cp -f PUBLICDIR/pbs_budg.sh . 
    bash PUBLICDIR/emu_budg.sh

elif [ "$emu_choice" -eq 7 ]; then
    echo "Modified Simulation Tool" > emu.lock
    echo "choice is 7) Modified Simulation Tool (msim)"
    echo "See PUBLICDIR/README_msim"
    cp -f PUBLICDIR/pbs_msim.sh pbs_msim.sh_orig
    bash PUBLICDIR/emu_msim.sh

elif [ "$emu_choice" -eq 8 ]; then
    echo "Attribution Tool" > emu.lock
    echo "choice is 8) Attribution Tool (atrb)"
    echo "See PUBLICDIR/README_atrb"
    bash PUBLICDIR/emu_atrb.sh

elif [ "$emu_choice" -eq 9 ]; then
    echo "Auxillary Tools" > emu.lock
    echo "choice is 9) Auxillary Tools (aux)"
    echo "See PUBLICDIR/README_aux"
    bash PUBLICDIR/emu_aux.sh

else
    echo "Invalid choice ... " $emu_choice
fi
cd ${returndir}
rm -f emu.lock  

else  
# Case when EMU is already running in current directory.
    echo "*** CONFLICT ***"
    read -r tdum < emu.lock
    echo "EMU " $tdum " is already running in this directory."
    echo "Wait until it finishes or run EMU in another directory." 
    echo "(or delete file emu.lock and rerun EMU if previous run was aborted.)" 
fi

#cd ${returndir}
echo ""
echo "EMU interactive execution complete. $(date)"
