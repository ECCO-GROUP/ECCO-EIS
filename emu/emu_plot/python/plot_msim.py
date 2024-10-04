# Read Modified Simulation Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy

# Create a custom colormap that maps masked values to gray
cmap = plt.cm.jet
cmap.set_bad(color='gray')  # Set the color for masked elements to gray

# --------------------------------------------
def plot_msim(frun):
    """
    Check Modified Simulation Tool output.
    
    Parameters:
    frun (str): The main run directory path.
    """
    
    # Set EMU output file directory
    frun_output = os.path.join(frun, 'diags')
    
    # Search files
    print('')
    print("Checking EMU standard model state output ... ")
    print('')
    
    # Assuming plot_state is a function that processes the data and populates the naa variables
    naa_2d_day, naa_2d_mon, naa_3d_mon = emupy.plot_state(frun_output)
    
    ndum = max(naa_2d_day, naa_2d_mon, naa_3d_mon)
    print('')
    print('*********************************************')
    
    if ndum != 0:
        print("EMU's standard model state output can be sampled using EMU's ")
        print("Sampling Tool, specifying the diag subdirectory of this run")
        print("in response to the Tool's prompt;")
        print(frun_output)
        print('')
    else:
        print("No diagnostic state output found in this run's diag subdirectory.")
        print(frun_output)
        print('')
    
    # Search subdirectories
    print('')
    print('*********************************************')
    print("Checking Budget output ... ")
    
    # Search for all subdirectories
    entries = glob.glob(os.path.join(frun_output, '*'))
    entries.sort()
    
    # Initialize the counter
    subdir_count = 0
    
    # Loop through the entries and count only directories
    for entry in entries:
        if os.path.isdir(entry):
            subdir_count += 1
    
    if subdir_count != 0:
        # Count total number of .data files in the subdirectories
        files = glob.glob(os.path.join(frun_output, '*/*.data'))
        files.sort()
        total_file_count = len(files)
        
        if total_file_count != 0:
            # Output # of subdirectories
            print('')
            print(f'Total number of subdirectories: {subdir_count}')
            
            # Initialize the second counter
            subdir_count2 = 0
            print('')
            
            # Loop through each subdirectory again and count number of .data files
            for entry in entries:
                if os.path.isdir(entry):
                    subdir_count2 += 1
                    
                    # Search for all files ending with .data in the directory
                    files = glob.glob(os.path.join(entry, '*.data'))
                    files.sort()
                    
                    # Count the number of .data files
                    file_count = len(files)
                    
                    # Print name of subdirectory and number of .data files
                    fname = os.path.basename(entry)
                    fdum = f'   {subdir_count2}) {fname} has {file_count} files'
                    print(fdum)
            
            print('')
            print('*********************************************')
            print("Budget output of this run can be analyzed using ")
            print("EMU's Budget Tool, specifying the diag subdirectory of this run")
            print("in response to the Tool's prompt;")
            print(os.path.join(frun, 'diags'))
            print('')
        else:
            print('')
            print("No budget output found in this run's diag subdirectory.")
            print(os.path.join(frun, 'diags'))
            print('')
    else:
        print("No budget output found in this run's diag subdirectory.")
        print(os.path.join(frun, 'diags'))
        print('')

