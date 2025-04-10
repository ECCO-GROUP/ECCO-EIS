#!/bin/bash -e 

umask 022

#====================================
# Shell script to create emu.sif 
#====================================

echo " "
echo "Creating EMU singularity image emu.sif ... "

# ----------------------------------------
# 1) Get EMU source code from Github 
echo 
echo "**** Step 1: Get EMU source code from Github"

git clone https://github.com/ECCO-GROUP/ECCO-EIS.git 
mv ECCO-EIS/emu .  
rm -rf ECCO-EIS  

# ----------------------------------------
# 2) Create forward code (ad_input_code.f)
echo 
echo "**** Step 2: Create forward code (ad_input_code.f)"

# a) Create code for various number of cores (nproc) inside a container. 
#    The codes will be placed in
#         /ecco/emu/exe/nproc/*
#    where * is the nproc value that is any of
#         [13, 36, 48, 68, 72, 96, 192, 360]
cp -f ./emu/singularity/sif_ad_input_code.def . 
singularity build --fakeroot sif_ad_input_code.sif sif_ad_input_code.def

# b) Copy code (directory nproc in a) from container to host. 
/bin/rm -f my_commands.sh
echo '#!/bin/bash -e' > my_commands.sh && chmod +x my_commands.sh
echo 'cp -r /ecco/emu/exe/nproc /inside_out'      >> my_commands.sh
     
singularity exec --bind ${PWD}:/inside_out \
     sif_ad_input_code.sif /inside_out/my_commands.sh

# ----------------------------------------
# 3) Create adjoint code (ad_taf_output.f) 
echo 
echo "**** Step 3: Create adjoint code (ad_taf_output.f)"

cp -f ./emu/singularity/sif_ad_taf_output.sh .

# Find all sub-directories from 2b) with ad_input_code.f
dirs=($(find . -type f -name "ad_input_code.f" -exec dirname {} \; | sort -u))

# Create ad_taf_output.f for each ad_input_code.f file
echo 
echo "Creating ad_taf_output.f for each ad_input_code.f ... " 
for dir in "${dirs[@]}"; do
    echo 
    echo "$dir"
    dir2=$(realpath $dir)
    ./sif_ad_taf_output.sh $dir2 
done

tar -cvf nproc.tar nproc 

# ----------------------------------------
# 4) Create sif file 
# Executables for 1), 2), and 3) will be compiled within the sif file. 

cp -f ./emu/singularity/sif.def . 
singularity build --fakeroot emu.sif sif.def



