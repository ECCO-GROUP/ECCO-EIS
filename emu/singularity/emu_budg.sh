#!/bin/bash 

#=================================
# Shell script for V4r4 Budget Tool
# Script does all three steps of the Tool;
#    1) setup_budg.csh
#    2) budg.x
#    3) do_budg.x
#=================================

native_singularity=NATIVE_SINGULARITY
singularity_image=SINGULARITY_IMAGE
native_setup=NATIVE_SETUP

echo " "
echo "************************************"
echo "    EMU Budget Tool (singularity) "
echo "************************************"

/bin/rm -f my_commands.sh
echo '#!/bin/bash' > my_commands.sh && chmod +x my_commands.sh
echo 'cd /inside_out'               >> my_commands.sh

# Step 1: Tool Setup
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 1: Tool Setup"'    >> my_commands.sh
echo 'echo "     Running setup_budg.sh"' >> my_commands.sh
echo '${basedir}/emu/setup_budg.sh'      >> my_commands.sh

# Step 2: Specification
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 2: Specification"' >> my_commands.sh
echo 'echo "     Running budg.x"'        >> my_commands.sh
echo './budg.x /emu_outside'             >> my_commands.sh

# Step 3: Calculation 
echo 'echo " "'                          >> my_commands.sh
echo 'echo "**** Step 3: Calculation"'   >> my_commands.sh
echo 'echo "     Running do_budg.x"'     >> my_commands.sh
echo 'read dummy < budg.dir_out'         >> my_commands.sh
echo 'cd ${dummy}/temp'                  >> my_commands.sh
echo 'ln -s ${basedir}/emu/do_budg.x .'  >> my_commands.sh
echo './do_budg.x /emu_outside'          >> my_commands.sh

${native_singularity} exec --bind ${native_setup}:/emu_outside:ro --bind ${PWD}:/inside_out \
     ${singularity_image} /inside_out/my_commands.sh

#=================================
# Move result to output dirctory 
returndir=$PWD

read dummy < budg.dir_out
cd ${PWD}/${dummy}/temp

mkdir ../output

mv data.ecco  ../output
mv budg.info ../output
mv emu_budg.*  ../output

echo " " 
dum=`tail -n 1 budg.dir_out`
echo '********************************************'
echo "    Results are in" $dum
echo '********************************************'
echo " "

cd ${returndir}
