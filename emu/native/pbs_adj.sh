#PBS -S /bin/bash
#CHOOSE_NODES
#PBS -l walltime=WHOURS_EMU:00:00
#PBS -j oe
#PBS -o ./
#PBS -m bea
#CHOOSE_DEVEL

umask 022

#=================================
# PBS script for V4r4 Adjoint Tool (native)
#=================================

#=================================
# Set program specific parameters 
nprocs=EMU_NPROC
emu_dir=EMU_DIR

rundir=YOURDIR

##=================================
# Set running environment 
ulimit -s unlimited

# set_modules.sh must be run by source 
source ${emu_dir}/emu/native/set_modules.sh

#=================================
# cd to directory to run rundir
cd ${rundir}
 
# ================================
# Run flux-forced V4r4 adjoint 
ln -sf ${emu_dir}/emu/exe/nproc/${nprocs}/v4r4_flx_ad.x .
ln -sf ${emu_dir}/emu/emu_input/nproc/${nprocs}/data.exch2 .

mpiexec -np ${nprocs} /u/scicon/tools/bin/mbind.x ./v4r4_flx_ad.x

#=================================
# Save adjoint gradients 

adoutdir=../output
mkdir ${adoutdir}

# adjoint gradient with respect to atmospheric controls 
mv adxx_empmr.0*.* ${adoutdir}
mv adxx_pload.0*.* ${adoutdir}
mv adxx_qnet.0*.* ${adoutdir}
mv adxx_qsw.0*.* ${adoutdir}
mv adxx_saltflux.0*.* ${adoutdir}
mv adxx_spflx.0*.* ${adoutdir}
mv adxx_tauu.0*.* ${adoutdir}
mv adxx_tauv.0*.* ${adoutdir}

# adjoint gradient with respect to initial condition 
mv adxx_etan.0*.* ${adoutdir}
mv adxx_theta.0*.* ${adoutdir}
mv adxx_salt.0*.* ${adoutdir}
mv adxx_uvel.0*.* ${adoutdir}
mv adxx_vvel.0*.* ${adoutdir}

# adjoint gradient with respect to mixing parameters 
mv adxx_diffkr.0*.* ${adoutdir}
mv adxx_kapgm.0*.* ${adoutdir}
mv adxx_kapredi.0*.* ${adoutdir}

mv data.ecco ${adoutdir}
mv data ${adoutdir}
mv adj.info ${adoutdir}

# master STDOUT & STDERR 
mv STDOUT.0000 ${adoutdir}
mv STDERR.0000 ${adoutdir}

#mv `realpath objf_*_mask*` ${adoutdir}
# Save mask
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_C'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_S'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_W'
PUBLICDIR/misc_move_files.sh ./ ${adoutdir} '*mask_T'

#=================================
# Delete tape files

/bin/rm -f tapes/tapes*

