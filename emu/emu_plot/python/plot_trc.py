# Read Tracer Tool output

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
def plot_trc(frun):
    # Read and plot Tracer Tool output
    
    # ---------------
    # Set EMU output file directory
    frun_output = os.path.join(frun, 'output')
    
    # ---------------
    # Search available output
    print('')
    
    # Find and count monthly mean files
    fdum = 'ptracer_mon_mean.*.data'
    aa_mon = glob.glob(os.path.join(frun_output, fdum))
    naa_mon = len(aa_mon)
    print(f'Detected {naa_mon:6} files of {fdum}')
    
    # Find and count snapshot files
    fdum = 'ptracer_mon_snap.*.data'
    aa_snap = glob.glob(os.path.join(frun_output, fdum))
    naa_snap = len(aa_snap)
    print(f'Detected {naa_snap:6} files of {fdum}')
    
    # Choose variable
    print('')
    fmd = input('Select monthly mean or snapshot ... (m/s)? ').lower()
    
    if fmd == 'm':
        print('')
        print('==> Reading and plotting monthly means ... ')
        
        # Assuming `rd_ptracer` is a function to read tracer data
        trc3d, ifile = rd_ptracer(aa_mon)
        
    elif fmd == 's':
        print('')
        print('==> Reading and plotting snapshots ... ')
        
        trc3d, ifile = rd_ptracer(aa_snap)
    
    emu.trc3d = trc3d

    print('')
    print('*********************************************')
    print('Returning variable ')
    print('   trc3d: last plotted tracer (3d)')
    print('')
    
    return trc3d

# --------------------------------------------
def rd_ptracer(ff):
    """
    Read and plot a record of a state_2d_set1 file.
    
    Parameters:
    ff (list): List of file paths to read
    irec (int): The record index (file number to read)
    
    Returns:
    trc (numpy array): 3D tracer data
    """

    n_ff = len(ff)
    trc = np.zeros((emu.nr, emu.ny, emu.nx), dtype=float)
    dum2d = np.zeros((emu.ny, emu.nx), dtype=float)

    # Create land mask
    ref2d = emupy.nat2globe(emu.hfacc[0, :, :])

    idum = 1
    ifile = 1

    # Loop among files
    while idum >= 1 and idum <= n_ff:
        print('')
        idum = int(input(f'Enter file # to read ... (1-{n_ff} or -1 to exit)? '))
        ifile = idum - 1
        if ifile < 0 or ifile >= n_ff:
            break

        print('')
        print(f'Reading file ... {ff[ifile]}')

        # Read tracer data from the file
        with open(ff[ifile], 'rb') as f:
            trc = np.fromfile(f, dtype='>f4').reshape((emu.nr, emu.ny, emu.nx))

        dum2d.fill(0)
        for k in range(emu.nr):
            dum2d += trc[k, :, :] * emu.drf[k] * emu.hfacc[k, :, :]

        dum2d_sum = np.sum(dum2d * emu.rac)

        fname = os.path.basename(ff[ifile])
        timestep = emupy.get_timestep(fname, 'ptracer_mon')

        print('')
        print(f'time-step              = {timestep}')
        print(f'global volume integral = {dum2d_sum}')

        # Scale
        dum = np.max(np.abs(dum2d))
        order_of_magnitude = np.floor(np.log10(np.abs(dum)))
        dscale = 10.0 ** (-order_of_magnitude)
        dum2d *= dscale

        # Plot
        dumg = emupy.nat2globe(dum2d)

        # Mask dry grid points 
        masked_dumg = np.ma.masked_where(ref2d == 0, dumg)

        ftitle = f'{ifile + 1} {fname} scaled by x{dscale:.0e}'

        plt.figure(figsize=(10,10))
        plt.title(ftitle)        
        plt.imshow(masked_dumg, origin='lower',cmap=cmap, aspect='auto')
        plt.colorbar()

        plt.ion()  # Enable interactive mode
        plt.show(block=False)  # Show the plot without blocking

    return trc, ifile
