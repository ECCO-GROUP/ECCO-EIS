#!/bin/bash 

#=================================
# Shell script for V4r4 Convolution Tool
# Script does all three steps of the Tool;
#    1) setup_conv.csh
#    2) conv.x
#    3) do_conv.csh
#=================================

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_setup=NATIVE_SETUP

echo " "
echo "************************************"
echo "    EMU Convolution Tool (singularity) "
echo "************************************"

/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh & chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 1: Tool Setup
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'    >> my_commands.sh
echo 'echo "     Running setup_conv.sh"' >> my_commands.sh
echo '${basedir}/emu/setup_conv.sh'      >> my_commands.sh

# Step 2: Specification
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 2: Specification"' >> my_commands.sh
echo 'echo "     Running conv.x"'        >> my_commands.sh
echo './conv.x /emu_outside '            >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

if [ -f "conv.dir_out" ] && [ -f "pbs_conv.sh" ]; then
    read dummy < "conv.dir_out"
    subdir=${dummy}/temp
    sed -i -e "s|SUBDIR|${subdir}|g" pbs_conv.sh
    rundir=${PWD}/${subdir}
    sed -i -e "s|YOURDIR|${rundir}|g" pbs_conv.sh
    cp -p pbs_conv.sh ${rundir}
else
    echo "File conv.dir_out and/or pbs_conv.sh do(es) not exist ... "
    exit 1
fi
# Step 3: Calculation 

echo " "                       
echo "**** Step 3: Calculation"
echo "     Running do_conv.x"
echo " "
echo "Do convolution (1) interactively or (2) in PBS ... (1/2)? " 

read conv_choice

if [ "$conv_choice" -eq 1 ]; then 
    /bin/rm -f my_commands.sh
    echo '#!/bin/bash' > my_commands.sh & chmod +x my_commands.sh
    echo 'cd /inside_out'               >> my_commands.sh
    echo 'read dummy < conv.dir_out'         >> my_commands.sh
    echo 'cd ${dummy}/temp'                  >> my_commands.sh
    echo 'ln -sf ${basedir}/emu/do_conv.x .' >> my_commands.sh
    echo 'seq 8 | parallel -j 8 -u --joblog conv.log "echo {} | do_conv.x"' >> my_commands.sh

    ${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${PWD}:/inside_out \
	${singularity_image} /inside_out/my_commands.sh

#=================================
# Move result to output dirctory 
    returndir=$PWD

    read dummy < conv.dir_out
    cd ${PWD}/${dummy}/temp

    mkdir ../output

    mv conv.info ../output
    mv conv.out  ../output
    mv istep_*.data ../output
    mv recon1d_*.data ../output
    mv recon2d_*.data ../output

    echo " " 
    dum=`tail -n 1 conv.dir_out`
    echo '********************************************'
    echo "    Results are in" $dum
    echo '********************************************'
    echo " "

    cd ${returndir}
else
    BATCH_COMMAND pbs_conv.sh

    echo "... Batch job pbs_conv.sh has been submitted "
    echo "    to compute the convolution." 

    echo " "
    echo "    Estimated wallclock time:"
    sed -n '3p' pbs_conv.sh

    echo " " 
    dum=`sed -n '3p' conv.dir_out`
    echo '********************************************'
    echo "    Results will be in " ${dum}
    echo '********************************************'
    echo " "
fi


