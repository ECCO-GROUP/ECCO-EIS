#!/bin/bash -e

umask 022

#=================================
# Shell script for V4r4 Tracer Tool
# Script does all three steps of the Tool;
#    1) setup_trc.csh
#    2) trc.x
#    3) do_trc.csh
#=================================

singularity_image=SINGULARITY_IMAGE
emu_input_dir=EMU_INPUT_DIR

echo " "
echo "************************************"
echo "    EMU Tracer Tool (singularity) "
echo "************************************"

# Step 0: Check required EMU Input 
fdum=${emu_input_dir}/forcing/other/flux-forced/state_weekly 
if [[ ! -d $fdum ]]; then 
    echo " "
    echo "ABORT: EMU Input for Tracer Tool not found;"
    echo $fdum
    echo "Run PUBLICDIR/emu_download_input.sh"
    echo "using ${emu_input_dir} as 'directory name to place EMU Input'" 
    echo "to download state_weekly needed for the Tracer Tool." 
    exit 1
fi

# 
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 1: Tool Setup
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'    >> my_commands.sh
echo 'echo "     Running setup_trc.sh"'  >> my_commands.sh
echo '${emu_dir}/emu/setup_trc.sh'       >> my_commands.sh

singularity exec --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 2: Specification
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 2: Specification"' >> my_commands.sh
echo 'echo "     Running trc.x"'         >> my_commands.sh
cp -f PUBLICDIR/mitgcm_timing.nml .
echo /emu_input_dir > ./input_setup_dir
echo './trc.x'                           >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

if [ -f "trc.dir_out" ] && [ -f "pbs_trc.sh" ]; then
    read dummy < "trc.dir_out"
    rundir=${PWD}/${dummy}/temp
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_trc.sh
    cp -p pbs_trc.sh ${rundir}
else
    echo "File trc.dir_out and/or pbs_trc.sh do(es) not exist ... "
    exit 1
fi

# Step 3: Calculation 
echo " "
echo "**** Step 3: Calculation"

returndir=$PWD

# prepare script for 1) inside Singularity 
echo "  1) Set up files for tracer integration "
echo "     Running do_trc_prep.sh"
echo " "

cd ${rundir}

# Initialize my_commands.sh
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh
echo '${emu_dir}/emu/singularity/do_trc_prep.sh'   >> my_commands.sh

singularity exec --bind ${emu_input_dir}:/emu_input_dir:ro --bind ${rundir}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

cd ${returndir}

# submit batch job to do 2)
echo "  2) Integrate tracer "
echo "     submitting pbs_trc.sh"
echo " "

#BATCH_COMMAND pbs_trc.sh

echo "... Running batch job pbs_trc.sh "
echo "    to compute passive tracer evolution."

echo " "
echo "    Estimated wallclock time:"
sed -n '3p' pbs_trc.sh

echo " " 
dum=`sed -n '3p' trc.dir_out`
echo '********************************************'
echo "    Results will be in " ${dum}
echo '********************************************'
echo " "

dum="${dum%output}temp"
echo "Progress of the computation can be monitored by"
echo "  ls -l ${dum}/diags/ptracer_mon_mean*data | wc -l "
echo "which counts the number of monthly mean tracer output files" 
echo "until completion when directory diags will be moved and this"
echo "command will return an error (No such file or directory)"
echo "and list zero as the count." 
echo " "

BATCH_COMMAND pbs_trc.sh
