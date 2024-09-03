#!/bin/bash -e 
umask 022

#=================================
# Shell script for EMU Attribution Tool (atrb)
#
# The Attribution Tool evaluates time-series of contributions from
# seperate types of controls to a user-defined variable of the ECCO
# estimate. Contributions are evaluated from results that were
# obtained using EMU's Modified Simulation Tool. The Attribution Tool
# is useful in identifying the type of control responsible for the
# variable's variation and to ascertain the accuracty of the model's
# adjoint when using the Convolution Tool.
#
#=================================

echo " "
echo "************************************"
echo "    EMU Attribution Tool (native) "
echo "************************************"

current_dir=${PWD}

toolname=atrb

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/emu_msim
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Attribution Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_input_setup.sh"
    echo "to download emu_msim needed for the Attribution Tool." 
    exit 1
fi

# ------------------------------------------
# Step 1: Tool Setup
# Step 2: Specification
echo " "
echo "**** Steps 1 & 2: Setup & Specification"
echo " " 

# Specify objective function 
/bin/cp -fp ${emu_dir}/emu/data.ecco_adj ./data.ecco
${emu_dir}/emu/exe/set_samp.x ${emu_input_dir}

echo " "
echo "Done interactive specification."
echo "Begin evaluating time-series ... "
echo " "
sleep 3

# Create directory for Tool
f_command=$(cat set_samp.out)
/bin/rm ./set_samp.out

dir_out="emu_"${toolname}"_"${f_command}

# Create directory or new one if it already exists
if [[ -d ./${dir_out} ]] ; then
    echo "**** WARNING: Directory exists already: "${dir_out}
    dir_out=${dir_out}"_"$(date +%Y%m%d)"_"$(date +%H%M%S)
    echo "**** Renaming output directory to: "${dir_out}
else
    echo "Tool output will be in: "${dir_out}
fi
mkdir ./${dir_out}

dir_run=${dir_out}/temp
mkdir ./${dir_run}

# Move files to run directory
mv ./set_samp.info ./${dir_run}
mv ./data.ecco ./${dir_run}
mv ./objf_*_T ./${dir_run}
for file in ./objf_*_{C,S,W}; do
    # Check if file exists
    if [ -e "${file}" ]; then
    # Check if file is a symbolic link 
	if [ -h "${file}" ]; then
	    source_file=$(readlink -f "./${file}")
	    ln -sf ${source_file} ./${dir_run}/${file}
	    rm ./${file}
	else
	    mv ./${file} ./${dir_run}
	fi
    fi
done

# Move to run directory
cd ./${dir_run}

# ------------------------------------------
# Sample different runs 

# reference run (emu_ref)
echo " "
echo "Sampling reference run ... "
frun=${emu_input_dir}/emu_ref/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_1
mv ./samp.out_* ./atrb.tmp_1

# run with time-mean wind (TAUX & TAUY)
echo " "
echo "Sampling time-mean wind run ... "
fvar="oceTAUX_oceTAUY"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_2
mv ./samp.out_* ./atrb.tmp_2

# run with time-mean heat flux (TFLUX & oceQsw)
echo " "
echo "Sampling time-mean heat flux run ... "
fvar="TFLUX_oceQsw"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_3
mv ./samp.out_* ./atrb.tmp_3

# run with time-mean freshwater flux (oceFWflx)
echo " "
echo "Sampling time-mean freshwater flux run ... "
fvar="oceFWflx"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_4
mv ./samp.out_* ./atrb.tmp_4

# run with time-mean salt flux (oceSflux & oceSPflx)
echo " "
echo "Sampling time-mean salt flux run ... "
fvar="oceSflux_oceSPflx"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_5
mv ./samp.out_* ./atrb.tmp_5

# run with time-mean pressure load (sIceLoadPatmPload_nopabar)
echo " "
echo "Sampling time-mean pressure load run ... "
fvar="sIceLoadPatmPload_nopabar"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_6
mv ./samp.out_* ./atrb.tmp_6

# run with time-mean initial condition (IC)
echo " "
echo "Sampling time-mean initial condition run ... "
fvar="IC"
frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags
echo "from: " ${frun}
${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_7
mv ./samp.out_* ./atrb.tmp_7

echo " "

# ------------------------------------------
# Compute individual contributions
echo "Computing individual control contribution ... "
${emu_dir}/emu/exe/do_atrb.x 

#=================================
# Move result to output dirctory 

mkdir ../output

mv ./data.ecco  ../output
mv ./set_samp.info ../output
mv ./atrb.out_* ../output
mv ./atrb.step_* ../output
mv ./atrb.txt  ../output

# Save mask
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_W'
PUBLICDIR/misc_move_files.sh ./ ../output '*mask_S'

echo " " 
dum=$(readlink -f ${PWD}/../output)
echo '********************************************'
echo "    Done. Results are in" $dum
echo '********************************************'
echo " "

cd ${current_dir}







