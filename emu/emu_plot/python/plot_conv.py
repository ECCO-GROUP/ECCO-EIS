# Read Convolution Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy
import plot_conv_sub

def plot_conv(frun): 
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    frun_output = os.path.join(frun, 'output')

    # ---------------
    # Search available output

    # Get maximum lag from the name of the run (frun) 
    ii = frun.rfind('_')  # Using rfind() for reverse search

    # Check if the length of the string after the last underscore is 7 (indicating date & time)
    if len(frun) - ii == 7:
        # Split the string by underscores
        parts = frun.split('_')
        # Extract the third part from the end
        nlag = parts[-3] + 1 # lag starts from zero, so number of lag is +1
    else:
        # Extract the substring after the last underscore and convert it to an integer
        nlag = int(frun[ii+1:]) + 1  # lag starts from zero, so number of lag is +1

    # Specify controls in file
    fctrl = ['empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv']
    nctrl = len(fctrl)  # Equivalent to n_elements(fctrl) in IDL

    # ---------------
    # Read recon1d (Reconstruction time-series summed in space, as a function of lag and control)
    nweeks = 1357  # Maximum number of weeks that should be in EMU Convolution Tool output

    # Create a 3D NumPy array (equivalent to fltarr in IDL)
    recon1d = np.zeros((nctrl, nlag, nweeks), dtype=np.float32)

    # Create a 2D NumPy array for temporary storage (equivalent to fltarr in IDL)
    dum = np.zeros((nlag, nweeks), dtype=np.float32)

    # Sum of all controls, initialized as a 2D array
    recon1d_sum = np.zeros((nlag, nweeks), dtype=np.float32)

    # Initialize recon1d_sum array
    recon1d_sum = np.zeros((nlag, nweeks), dtype=np.float32)

    for i in range(nctrl):
        # Build the file name
        ff = os.path.join(frun_output, f'recon1d_{fctrl[i]}.data')

        # Check if the file exists
        if not os.path.exists(ff):
            print('*********************************************')
            print(f'No recon1d_{fctrl[i]}.data file found ... ')
            print('')
            exit()  # Exit the loop if the file is not found

        # Read the binary data from the file, assuming float32 and swap byte order if needed
        with open(ff, 'rb') as file:
            print(file)
            dum = np.fromfile(file, dtype=byte_order+'f4').reshape(nlag,nweeks)  # Assuming data is stored in float32 format
#            dum = np.fromfile(file, dtype=np.float32)  # Assuming data is stored in float32 format
#            dum = dum.reshape((nlag, nweeks))  # Reshape to match the dimensions

        # Store the data in recon1d
        recon1d[i, :, :] = dum

    # Save recon1d as global variable 
    emu.recon1d = recon1d

    # Initialize recon1d_sum with the first control's data
    recon1d_sum = np.copy(recon1d[0, :, :])

    # Sum the data across all controls
    for i in range(1, nctrl):
        recon1d_sum += recon1d[i, :, :]

    print('*********************************************')
    print('Read variable recon1d, the global spatial sum time-series')
    print('of the convolution as a function of lag and control.')
    print('   recon1d: adjoint gradient reconstruction')
    print('from file recon1d_*.data')
    print('')

    # -------------------------
    # Initialize istep array (equivalent to lonarr in IDL, assuming it's a 32-bit integer)
    istep = np.zeros(nweeks, dtype=np.int32)

    # Read the 'istep' file (all istep files are identical, so just read one)
    i = 0
    ff = os.path.join(frun_output, f'istep_{fctrl[i]}.data')

    # Check if the file exists
    if not os.path.exists(ff):
        print('*********************************************')
        print(f'No istep_{fctrl[i]}.data file found ... ')
        print('')
        exit()  # Exit if the file is not found

    # Read the binary data from the file, assuming int32 format
    with open(ff, 'rb') as file:
        istep = np.fromfile(file, dtype=byte_order+'i4')

    emu.istep = istep

    # Perform the time conversion
    ww = istep.astype(np.float32) / 24. / 365. + 1992.  # Convert to years since 1992
    wwmin = int(np.floor(np.min(ww)) - 1)  # Calculate the minimum year, rounding down
    wwmax = int(np.ceil(np.max(ww)) + 1)   # Calculate the maximum year, rounding up

    # Print the results
    print('*********************************************')
    print('Read variable ')
    print('   istep: time (hours since 1/1/1992 12Z) of recon1d ')
    print('from file istep_empmr.data')
    print('')
    print(f'Minimum year: {wwmin}')
    print(f'Maximum year: {wwmax}')

    # -------------------------
    # Compute Explained Variance vs lag (with all controls)

    vref = emupy.lib_var(recon1d_sum[nlag - 1, :])  # Calculate variance for the reference (max lag)
    ev_lag = np.zeros(nlag, dtype=np.float32)  # Initialize explained variance array for lag

    for i in range(nlag):
        ev_lag[i] = 1.0 - emupy.lib_var(recon1d_sum[nlag - 1, :] - recon1d_sum[i, :]) / vref

    tlag = np.arange(nlag, dtype=np.float32)

    emu.ev_lag = ev_lag

    print('*********************************************')
    print('Computed Explained Variance (EV) vs lag with all controls.')
    print('   ev_lag: EV as function of lag')
    print('')

    # Explained Variance vs control (at max lag)

    recon_all = np.zeros(nweeks, dtype=np.float32)  # Initialize array for recon_all
    recon_by_ctrl = np.zeros((nctrl, nweeks), dtype=np.float32)  # Initialize array for recon_by_ctrl

    recon_all[:] = recon1d_sum[nlag - 1, :]  # Assign data at max lag to recon_all

    for ic in range(nctrl):
        recon_by_ctrl[ic, :] = recon1d[ic, nlag - 1, :]  # Assign data for each control at max lag

    vref = emupy.lib_var(recon_all)  # Calculate variance for recon_all
    ev_ctrl = np.zeros(nctrl, dtype=np.float32)  # Initialize explained variance array for controls

    for ic in range(nctrl):
        ev_ctrl[ic] = 1.0 - emupy.lib_var(recon_all - recon_by_ctrl[ic, :]) / vref

    emu.ev_ctrl = ev_ctrl

    print('*********************************************')
    print('Computed Explained Variance (EV) vs control at maximum lag.')
    print('   ev_ctrl: EV as function of control')
    print('')

    tctrl = np.arange(1, nctrl + 1)  # Generate control time steps (1 to nctrl)
    tctrl_min = np.min(tctrl) - 1
    tctrl_max = np.max(tctrl) + 1

    # -------------------------
    # Plot

    ip = nlag - 1  # IDL counts from zero

    while 0 <= ip <= nlag-1:

        # Plot reconstruction
        plt.figure(figsize=(10, 5))
    
        fdum = f'recon1d: reconstruction at lag={ip}'
    
        # Plot the sum of reconstructions
        plt.subplot(2, 1, 1)
        plt.plot(ww, recon1d_sum[ip, :], label='sum')
        plt.title(fdum)
        plt.xlim(wwmin, wwmax)
        plt.xlabel('Time (years)')
    
        # Access the color cycle from the rcParams
        prop_cycle = plt.rcParams['axes.prop_cycle']
        colors = prop_cycle.by_key()['color']  # Retrieve the list of colors from the color cycle

#        # Get the color cycle from the current axes
#        prop_cycle = plt.gca().prop_cycle
#        colors = prop_cycle.by_key()['color']  

        # Plot each control
        for i in range(nctrl):
            plt.plot(ww, recon1d[i, ip, :], label=fctrl[i], color=colors[i])
    
        plt.legend()
    
        # Plot explained variance vs lag
        plt.subplot(2, 2, 3)
        plt.plot(tlag, ev_lag, label='Exp Var vs lag (ev_lag)')
        plt.scatter([tlag[ip]], [ev_lag[ip]], color='red', s=100, zorder=5)
        plt.xlabel('Lag (wks)')
        plt.ylabel('Explained Variance')
        plt.title('Explained Variance vs Lag')

        # Plot explained variance vs control
        plt.subplot(2, 2, 4)
        plt.plot(tctrl, ev_ctrl, label='Exp Var vs ctrl (ev_ctrl)')

#        plt.scatter(tctrl, ev_ctrl, color=plt.cm.viridis(cc/cmax), s=100)
#        plt.scatter(tctrl, ev_ctrl, s=100)
        # Use the same colors for scatter points as used in the 1st plot
        for i in range(nctrl):
            plt.scatter(tctrl[i], ev_ctrl[i], s=100, color=colors[i])

        plt.title(f'Explained Variance vs Control @ lag={nlag-1}')
        plt.xlabel('Controls')
        plt.ylabel('Explained Variance')
        plt.xticks(tctrl, fctrl)
        plt.xlim(tctrl_min, tctrl_max)
    
        plt.tight_layout()
        plt.show(block=False)
    
        # Ask for new lag input
        ip = int(input(f'Enter lag to plot ... (0-{nlag-1} or -1 to exit)? ')) 

        if not (0 <= ip <= nlag-1):
            break

    # ---------------
    # Optionally read recon2d and compute explained variance as a function
    # of space

    # Initialize
    rd_recon2d = 'no'

    # Prompt the user
    print('')
    rd_recon2d = input('Read recon2d to compute explained variance vs space ... (y/n)? ')

    # Test for 'y' or 'Y'
    do_recon2d = 'y' in rd_recon2d.lower()

    # Output the result
    if do_recon2d:
        ev_space = plot_conv_sub.plot_conv_recon2d(frun, fctrl, recon1d_sum)
    else:
        ev_space = 'not computed'
        
    emu.ev_space = ev_space 


