# Read and plot EMU output 
#

class TerminateScriptException(Exception):
    """Custom exception to terminate script execution."""
    pass

# ---------------
import sys
import os
import glob
import numpy as np

# Add EMU's directory to the Python path
sys.path.append(os.path.dirname(__file__))

import global_emu_var as emu
import rd_grid
import lib_python as emupy

try:
    # ---------------
    # Read emu_ref location
    emu_plot_dir=os.path.dirname(__file__)
    emu_access_dir=os.path.dirname(emu_plot_dir)

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
    
    # ---------------
    # Read model grid information 
    
    # Initialize the grid with the path to the data directory
    emu_ref = emu_input_dir + "/emu_ref"
    rd_grid.rd_grid(emu_ref)
    
    # ---------------
    # Read EMU output
    

    # ---------------
    # Read in mask from EMU 

    fmask = input("Enter EMU-made 3D mask file name ... ?")

    msk = np.zeros((emu.nr, emu.ny, emu.nx), dtype=np.float32)

    # Read the file in little-endian format if necessary
    with open(fmask, 'rb') as file:
        msk = np.fromfile(file, dtype='>f4').reshape((emu.nr, emu.ny, emu.nx))

    # ---------------
    # Create rectified mask 

    ok = np.where(emu.dvol3d != 0)

    msk2 = np.zeros((emu.nr, emu.ny, emu.nx), dtype=np.float32)
    msk2[ok] = msk[ok] / emu.dvol3d[ok]

    fout = fmask + '_rectified_py'
    print("Rectified mask output to ...", fout)

    # Write the rectified mask to the output file in little-endian format
    with open(fout, 'wb') as file:
        msk2.astype('>f4').tofile(file)

except TerminateScriptException as e:
    print(f"Caught exception: {e}")
    
    
    
    
