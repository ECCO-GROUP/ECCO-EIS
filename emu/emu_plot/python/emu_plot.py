# Read and plot EMU output 
#

class TerminateScriptException(Exception):
    """Custom exception to terminate script execution."""
    pass

# ---------------
import sys
import os
import glob

# Add EMU's directory to the Python path
sys.path.append(os.path.dirname(__file__))

import global_emu_var as emu
import rd_grid
import lib_python as emupy

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
    
    frun_temp = None
    print()
    frun_temp = input("Enter directory of EMU run to examine; e.g., emu_samp_m_2_45_585_1 ... ? ")
    if not os.path.isdir(frun_temp):
        print(f"The directory {frun_temp} does not exist.")
        raise TerminateScriptException(f"Directory {frun_temp} does not exist.")  # Raise custom exception
        
    frun_temp_chk=emupy.lib_chk_emu_name(frun_temp)
    if frun_temp_chk == ' ':
        raise TerminateScriptException(f"Directory name {frun_temp} does not conform to EMU syntax.")  # Raise custom exception

    frun = os.path.abspath(frun_temp_chk)
    
    print()
    print(f"Reading {frun}")
    
    # ----------------
    ftool = id_tool(frun)
    #print("Tool is :", ftool)
    print()
    
    if ftool == 'samp':
        import plot_samp 
        print("Reading Sampling Tool output ... ")
        plot_samp.plot_samp(frun)
    
    elif ftool == 'fgrd':
        import plot_fgrd 
        print("Reading Forward Gradient Tool output ... ")
        plot_fgrd.plot_fgrd(frun)
    
    elif ftool == 'adj':
        import plot_adj 
        print("Reading Adjoint Tool output ... ")
        plot_adj.plot_adj(frun)
    
    elif ftool == 'conv':
        import plot_conv 
        print("Reading Convolution Tool output ... ")
        plot_conv.plot_conv(frun)
    
    elif ftool == 'trc':
        import plot_trc
        print("Reading Tracer Tool output ... ")
        plot_trc.plot_trc(frun)
    
    elif ftool == 'budg':
        import plot_budg 
        print("Reading Budget Tool output ... ")
        plot_budg.plot_budg(frun)
    
    elif ftool == 'msim':
        import plot_msim
        print("Reading Modified Simulation Tool output ... ")
        plot_msim.plot_msim(frun)
    
    elif ftool == 'atrb':
        import plot_atrb
        print("Reading Attribution Tool output ... ")
        plot_atrb.plot_atrb(frun)
        
    else:
        print(f"Corresponding Tool not found  ... {ftool}")
    
    # ---------------
    # Summary of variables read 
    
    # List all attributes in global variables 
    attributes = dir(emu)
    
    # Filter to include only non-callable, non-special, and non-None variables
    variables = [
        attr for attr in attributes
        if not callable(getattr(emu, attr))
        and not attr.startswith("__")
        and getattr(emu, attr) is not None
    ]
    
    # Print the variable names and their values in table format
    print()
    print(f'***********************')
    print(f'EMU variables read as global variables in module global_emu_var (emu); e.g., emu.nx')
    print(f'***********************')
    
    columns = 4  # Define the number of columns you want
    
    # Group the variables into rows with the specified number of columns
    for i, var in enumerate(variables):
        #value = getattr(emu, var)
        #print(f"{var} = {value}")
        print(f"{var:<20}", end="")  # Adjust the width to align the columns
        if (i + 1) % columns == 0:
            print()  # Start a new line after printing the specified number of columns
    
    # Print a new line at the end, if the last row doesn't fill up all columns
    if len(variables) % columns != 0:
        print()

except TerminateScriptException as e:
    print(f"Caught exception: {e}")
    
    
    
    
