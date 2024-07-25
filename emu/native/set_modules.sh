# Set modules for running MITgcm 
#
# NOTE: This shell script must be sourced; 
#          pfe20> source set_modules.sh
#       Otherwise, the environment will not apply to the shell that
#       this was called from.
#

module purge
module load comp-intel/2020.4.304
module load mpi-hpe/mpt
module load hdf4/4.2.12
module load hdf5/1.8.18_mpt
module load netcdf/4.4.1.1_mpt
module load python3/3.9.12
module list

