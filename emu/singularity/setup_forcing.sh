#!/bin/bash -e

umask 022

#
# Create link to outside files needed to run flux-forced V4r4
#

# Link outside files 
ln -sf /emu_input_dir/forcing/other/flux-forced/forcing/* .
ln -sf /emu_input_dir/forcing/other/flux-forced/xx/* .

ln -sf /emu_input_dir/forcing/input_init/error_weight/ctrl_weight/* .
ln -sf /emu_input_dir/forcing/input_init/* .
ln -sf /emu_input_dir/forcing/input_init/tools/* .

ln -sf /emu_input_dir/emu_ref/pickup*.data .

# Set up files reflecting folding initial condition & parameter
# control adjustments to respective controls. The following sets up 
# control files that have been updated with the adjustments and
# control adjustment files that are all zero. 
ln -sf /emu_input_dir/forcing/other/flux-forced/input_init/* .
mv -f pickup_ecco.0000008772.data        pickup_ecco.0000000001.data
mv -f pickup.0000000001.data.V4r4_tot    pickup.0000000001.data
mv -f xx_diffkr.effective.V4r4           total_diffkr_r009bit11.bin 
mv -f xx_kapgm.effective.V4r4		 total_kapgm_r009bit11.bin 
mv -f xx_kapredi.effective.V4r4		 total_kapredi_r009bit11.bin
