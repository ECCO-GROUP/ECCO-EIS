# Read Adjoint Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy

# Create a custom colormap that maps masked values to gray
cmap = plt.cm.jet
cmap.set_bad(color='gray')  # Set the color for masked elements to gray

def plot_adj(frun): 
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    ff = os.path.join(frun, 'output')

    # specify controls in file 
    fctrl = ['empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv']
    nctrl=len(fctrl)

    emu.adj_ctrl=fctrl

    print()
    print('Choose control to plot ... ')
    for i in range(nctrl): 
        print(f"{i+1}) {fctrl[i]}")

        # Loop until a valid input is received
    print()
    while True:
        try:
            # Prompt the user for input
            ictrl = int(input(f'Enter control # to plot ... (1-{nctrl})? ')) - 1
            
            # Check if the input is within the valid range
            if 0 <= ictrl <= nctrl-1:
                # print(f'Plotting control ... {fctrl[{ictrl}]}')
                print(f'Plotting control ... {fctrl[ictrl]}')
                break  # Exit the loop if valid input is received
            else:
                print(f"Enter a number between 1 and {nctrl}.")
        except ValueError:
                # Handle non-integer inputs
                print("Invalid input. Enter an integer.")

    # Construct the file search pattern
    fdum = f"adxx_{fctrl[ictrl]}.*.data"
    search_pattern = os.path.join(ff, fdum)

    # Search for files matching the pattern
    aa = glob.glob(search_pattern)
    naa = len(aa)

    if naa != 1:
        if naa == 0:
            print('*********************************************')
            print(f'File {fdum} not found ...')
            print('')
        else:
            print('*********************************************')
            print(f'More than one {fdum} found ...')
            print('')
    else:
        # Get the base name of the first found file
        fname = os.path.basename(aa[0])
        print(f'Found file: {fname}')

    # ---------------
    # Read entire adxx time-series 

    # number of 2d records
    nadxx = os.path.getsize(aa[0]) // (emu.nx * emu.ny * 4)

    # Initialize the array
    adxx = np.zeros((nadxx, emu.ny, emu.nx), dtype=np.float32)

    # Open the file and read binary data with proper endianness handling
    with open(aa[0], 'rb') as f:
        # Read the entire data into the array
        adxx = np.fromfile(f, dtype=byte_order+'f4').reshape(nadxx, emu.ny, emu.nx)

    emu.adxx = adxx

    print()
    print('*********************************************')
    print(f'Read adjoint gradient for {fctrl[ictrl]}')
    print('   adxx: adjoint gradient as a function of space and lag')
    print(f'from file {aa[0]}')

    # ---------------
    # Identify record that is 0-lag 
    lag0 = 0
    for j in range(nadxx - 1, 0, -1):
        dum = np.max(np.abs(adxx[j, :, :]))
        if dum != 0 and lag0 < j:
            lag0 = j

    # Identify the longest non-zero lag
    lagmax = nadxx - 1
    for j in range(nadxx):
        dum = np.max(np.abs(adxx[j, :, :]))
        if dum != 0 and lagmax > j:
            lagmax = j

    # Output results
    print(' ')
    print('Zero lag at (week/record) =', lag0 + 1)
    print('Max  lag at (week/record) =', lagmax + 1)

    # ---------------
    # Plot maps of adxx at select lags

    ref2d = emupy.nat2globe(emu.hfacc[0,:,:])
    landg = np.where(ref2d == 0)
    nlandg = len(landg[0])  

    print()
    print('*********************************************')
    print('Plotting maps of adxx at select lags ...')

    idum = 0
    while 0 <= idum <= (lag0 - lagmax):
        print('')
        user_input = input(f'Enter lag (# of weeks) to plot ... (0-{lag0 - lagmax} or -1 to exit)? ')

        try:
            idum = int(user_input)
        except ValueError:
            print("Not an integer.")
            break 

        irec = lag0 - idum
        if irec < lagmax or irec > lag0:
            print("Lag outside range. Breaking out of plotting image.")
            break

        dum2d = adxx[irec, :, :]

        # scale 
        dum = np.max(np.abs(dum2d))
        if dum != 0:
            order_of_magnitude = np.floor(np.log10(np.abs(dum)))
            dscale = 10 ** (-order_of_magnitude)
        else:
            dscale = 0.0

        dum2d = dum2d * dscale 
        dumg = emupy.nat2globe(dum2d)

        # Mask dry grid points 
        masked_dumg = np.ma.masked_where(ref2d == 0, dumg)

#        plt.close(10)
#        plt.figure(num=10, figsize=(10,10))
        plt.figure(figsize=(10,10))
        ftitle = f'lag, rec = {idum}, {irec + 1} {fname} scaled by x{dscale:.0e}'
        plt.title(ftitle)        
        plt.imshow(masked_dumg, origin='lower',cmap=cmap, aspect='auto')
        plt.colorbar()

        plt.ion()  # Enable interactive mode
        plt.show(block=False)  # Show the plot without blocking

    # ---------------
    # Plot time-series of adxx at select locations 

    print()
    print('*********************************************')
    print('Plotting time-series of adxx at select locations ...')


    nlag = lag0-lagmax+1
    ww = np.arange(nlag)
    iww = lag0 - np.arange(nlag)

    valid_pt = 1
    while valid_pt == 1:
        print('\nPress 1 to continue or 2 to exit ... (1/2)?')
        try:
            valid_pt = int(input().strip())
        except ValueError:
            print("Invalid input. Exiting.")
            break
           
        if valid_pt != 1:
            break

        xlon, ylat, ix, jy = emupy.slct_2d_pt()

        # Create the title string
        ftitle = f'(i,j,lon,lat)= {ix:2},{jy:4}  {xlon:7.1f} {ylat:6.1f} {fname}'

        # Plot using Matplotlib
#        plt.close(1)
#        plt.figure(num=1, figsize=(10,10))
        plt.figure(figsize=(10,10))
        plt.plot(ww, adxx[iww, jy-1, ix-1])
        plt.title(ftitle)
        plt.xlabel('lag (weeks)')
        plt.ylabel('adxx')  
        plt.grid(True)

        plt.ion()  # Enable interactive mode
        plt.show(block=False)  # Show the plot without blocking
