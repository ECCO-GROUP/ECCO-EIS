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

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Attribution Tool (singularity) "
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

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# ------------------------------------------
# Step 1: Tool Setup
# Step 2: Specification
echo " "
echo "**** Steps 1 & 2: Setup & Specification"
echo " " 

# Specify objective function 
echo '/bin/cp -fp ${emu_dir}/emu/data.ecco_adj ./data.ecco' >> my_commands.sh
echo '${emu_dir}/emu/exe/set_samp.x /emu_input_dir'         >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

echo " "
echo "Done interactive specification."
echo "Begin evaluating time-series ... "
echo " "
sleep 3

# Create directory for Tool
if [[ ! -f ./set_samp.out ]]; then
    echo "ERROR: set_samp.out not found. Aborting."
    exit 1
fi
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
    # If link, copy source as singularity will generally not have access to it
	    source_file=$(readlink -f "${file}")
	    cp -f ${source_file} ./${dir_run}
	    base_name=$(basename "${source_file}")
	    if [ ! -e "./${dir_run}/${file}" ]; then
		ln -s ./${base_name} ./${dir_run}/${file}
	    fi
	else
	    mv ./${file} ./${dir_run}
	fi
    fi
done

# Move to run directory
cd ./${dir_run}

# ------------------------------------------
# Sample different runs 

# Initialize my_commands.sh for Singularity image
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# reference run (emu_ref)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling reference run ... " '                   >> my_commands.sh
echo 'frun=/emu_input_dir/emu_ref/diags '                    >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_1 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_1 '                         >> my_commands.sh

# run with time-mean wind (TAUX & TAUY)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean wind run ... " '              >> my_commands.sh
echo 'fvar="oceTAUX_oceTAUY" '                               >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags '      >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_2 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_2 '                         >> my_commands.sh

# run with time-mean heat flux (TFLUX & oceQsw)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean heat flux run ... " '         >> my_commands.sh
echo 'fvar="TFLUX_oceQsw" '                                  >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags '      >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_3 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_3 '                         >> my_commands.sh

# run with time-mean freshwater flux (oceFWflx)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean freshwater flux run ... " '   >> my_commands.sh
echo 'fvar="oceFWflx" '                                      >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags '      >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_4 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_4 '                         >> my_commands.sh

# run with time-mean salt flux (oceSflux & oceSPflx)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean salt flux run ... " '         >> my_commands.sh
echo 'fvar="oceSflux_oceSPflx" '                             >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags'       >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_5'   >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_5 '                         >> my_commands.sh

# run with time-mean pressure load (sIceLoadPatmPload_nopabar)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean pressure load run ... " '     >> my_commands.sh
echo 'fvar="sIceLoadPatmPload_nopabar" '                     >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags '      >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_6 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_6 '                         >> my_commands.sh

# run with time-mean initial condition (IC)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean initial condition run ... " ' >> my_commands.sh
echo 'fvar="IC" '                                            >> my_commands.sh
echo 'frun=/emu_input_dir/emu_msim/mean_${fvar}/diags '      >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_7 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_7 '                         >> my_commands.sh

# run with everything time-mean (ALL)
echo 'echo " "   '                                           >> my_commands.sh
echo 'echo "Sampling time-mean everything run ... " '        >> my_commands.sh
echo 'fvar="ALL" '                                           >> my_commands.sh
echo 'frun=${emu_input_dir}/emu_msim/mean_${fvar}/diags '    >> my_commands.sh
echo 'echo "from: " ${frun} '                                >> my_commands.sh
echo '${emu_dir}/emu/exe/do_samp.x ${frun} > ./atrb.prt_8 '  >> my_commands.sh
echo 'mv ./samp.out_* ./atrb.tmp_8 '                         >> my_commands.sh

echo 'echo " "   '                                           >> my_commands.sh

# ------------------------------------------
# Compute individual contributions
echo 'echo "Computing individual control contribution ... " ' >> my_commands.sh
echo '${emu_dir}/emu/exe/do_atrb.x '                          >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

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







