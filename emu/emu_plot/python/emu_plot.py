# Read and plot EMU output 
#

class TerminateScriptException(Exception):
    """Custom exception to terminate script execution."""
    pass

# ---------------
import sys
import os

# Add EMU's directory to the Python path
sys.path.append(os.path.dirname(__file__))

# ---------------
# Read emu_ref location
emu_plot_dir=os.path.dirname(__file__)
emu_access_dir=os.path.dirname(emu_plot_dir)

import glob

# Search for files matching the pattern emu_env.* but not emu_env.sh
pattern = os.path.join(emu_access_dir, 'emu_env.*')
files = glob.glob(pattern)
filtered_files = [f for f in files if not f.endswith('.sh')]

# Check if only one file matches the criteria
if len(filtered_files) == 1:
    file_path = filtered_files[0]
    print(f"Found file: {file_path}")
    
    # Initialize emu_input_dir variable
    emu_input_dir = None
    
    # Read the file as a text file and search for lines starting with 'input_'
    with open(file_path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line.startswith('input_'):
                # Assign what is after 'input_' to emu_input_dir
                emu_input_dir = line.strip()[len('input_'):]
                print(f"EMU Input Files directory: {emu_input_dir}")
                break  # Assuming you only need the first occurrence
else:
    print(f"Error: There are either no files or more than one file excluding emu_env.sh in the directory.")
    raise TerminateScriptException("No emu_env files or more than one excluding emu_env.sh in the directory.")  # Raise custom exception

import global_emu_var as emu

# ---------------
# Read model grid information 

import rd_grid

# Initialize the grid with the path to the data directory
emu_ref = emu_input_dir + "/emu_ref"
rd_grid.rd_grid(emu_ref)

# ---------------
# Read EMU output

frun_temp = None
print()
frun_temp = input("Enter directory of EMU run to examine; e.g., emu_samp_m_2_45_585_1 ... ? ")
if not os.path.isdir(frun_temp):
    print(f"The directory {frun_temp} does not exist.")
    raise TerminateScriptException("EMU run directory {frun_temp} does not exist.")  # Raise custom exception

frun = os.path.abspath(frun_temp)
print()
print(f"Reading {frun}")

# ----------------
# Code to ID EMU tool 
def id_tool(frun):
    # Get the file name from the full pathname
    filename = os.path.basename(frun)

    # Find the positions of the first and second underscores
    first_underscore = filename.find('_')
    if first_underscore == -1:
        print("Error: Underscore not found in run directory name.")
        print("Error: Does not conform to EMU syntax.")
        raise TerminateScriptException("Underscore not found in run directory name.")  # Raise custom exception

    second_underscore = filename.find('_', first_underscore + 1)
    if second_underscore == -1:
        print("Error: Less than two underscores in run directory name.")
        print("Error: Does not conform to EMU syntax.")
        raise TerminateScriptException("Less than two underscores in run directory name.")  # Raise custom exception

    # Extract the part of the string between the first and second underscores
    part1 = filename[:first_underscore]
    part2 = filename[first_underscore + 1:second_underscore]
    if part1 != 'emu':
        print("Error: part1 is not equal to 'emu'. ")
        print("Error: Does not conform to EMU syntax.")
        raise TerminateScriptException("Run directory name does not start with emu.")  # Raise custom exception

    return part2

# ----------------

ftool = id_tool(frun)
#print("Tool is :", ftool)
print()

if ftool == 'samp':
    import plot_samp 

    print("Reading Sampling Tool output ... ")
    plot_samp.plot_samp(frun)

#if (ftool eq 'samp') then begin
#   print,'Reading Sampling Tool output .. ' 
#   plot_samp,frun, smp, smp_mn, smp_sec
#   endif 
#if (ftool eq 'fgrd') then begin
#   print,'Reading Forward Gradient Tool output .. ' 
#   plot_fgrd, frun, fgrd2d
#   endif 
if ftool == 'adj':
    import plot_adj 

    print("Reading Adjoint Tool output ... ")
    plot_adj.plot_adj(frun)

#if (ftool eq 'conv') then begin
#   print,'Reading Convolution Tool output .. ' 
#   plot_conv, frun, recon1d, istep, fctrl, ev_lag, ev_ctrl, ev_space
#   endif 
#if (ftool eq 'trc') then begin
#   print,'Reading Tracer Tool output .. ' 
#   plot_trc, frun, trc3d
#   endif 
#if (ftool eq 'budg') then begin
#   print,'Reading Budget Tool output .. ' 
#   plot_budg, frun, emu_tend, emu_tend_name, emu_tint, emu_tint_name, budg_msk, budg_mkup, nmkup
#endif 
#if (ftool eq 'msim') then begin
#   plot_msim, frun, fld2d
#endif 
if ftool == 'atrb':
    import plot_atrb

    print("Reading Attribution Tool output ... ")
    plot_atrb.plot_atrb(frun)

#
#end
#
