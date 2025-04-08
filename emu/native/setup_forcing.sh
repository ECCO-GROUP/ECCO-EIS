#!/bin/bash -e

umask 022

#
# Create link to outside files neede to run flux-forced V4r4
#

# Link outside files 
ln -sf ${emu_input_dir}/forcing/other/flux-forced/forcing/* .
ln -sf ${emu_input_dir}/forcing/other/flux-forced/xx/* .

ln -sf ${emu_input_dir}/forcing/input_init/error_weight/ctrl_weight/* .
ln -sf ${emu_input_dir}/forcing/input_init/* .
ln -sf ${emu_input_dir}/forcing/input_init/tools/* .

ln -sf ${emu_input_dir}/emu_ref/pickup*.data .
