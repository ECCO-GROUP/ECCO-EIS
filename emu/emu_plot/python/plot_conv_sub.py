import os
import numpy as np
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy

# Create a custom colormap that maps masked values to gray
cmap = plt.cm.jet
cmap.set_bad(color='gray')  # Set the color for masked elements to gray

def plot_conv_recon2d(frun, fctrl, recon1d_sum):
    """
    Read Convolution Tool output recon2d_*.data and compute explained variance vs space (ev_space).
    """

    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    print('Reading recon2d_*.data and computing explained variance vs space (ev_space) ...')
    print('')
    print('Variable recon2d is the adjoint gradient reconstruction (time-series)')
    print('as a function of space by a particular control using the maximum lag')
    print('chosen in the convolution. Here, recon2d is read to compute the explained')
    print('variance vs space (ev_space), but recon2d is not retained by this plotting')
    print('routine to minimize memory usage.')
    print('')

    # Get dimensions
    nctrl = len(fctrl)
    nlag, nweeks = recon1d_sum.shape

    # Set EMU output file directory
    frun_output = os.path.join(frun, 'output')

    # Initialize arrays
    recon2d = np.zeros((nweeks, emu.ny, emu.nx), dtype=np.float32)
    ev_space = np.zeros((nctrl, emu.ny, emu.nx), dtype=np.float32)  # EV as a function of space for each control

    recon_all = recon1d_sum[nlag - 1, :]  # Full reconstruction up to maximum lag
    var_all = emupy.lib_var(recon_all)  # Variance of recon_all

    ref2d = emupy.nat2globe(emu.hfacc[0,:,:])

    dum2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)
    ok_rac = np.where(emu.rac != 0)  # Indices where grid area is non-zero

    # Check if ev_space has already been computed and saved
    ff_ev_space = os.path.join(frun_output, 'plot_conv_recon2d.ev_space')

    if not os.path.exists(ff_ev_space):
        # Compute ev_space if the file does not exist
        for ic in range(nctrl):
            ff = os.path.join(frun_output, f'recon2d_{fctrl[ic]}.data')

            if not os.path.exists(ff):
                print('*********************************************')
                print(f'No recon2d_{fctrl[ic]}.data file found ... ')
                print('')
                return

            # Read recon2d data for the specific control
            with open(ff, 'rb') as f:
                recon2d = np.fromfile(f, dtype=byte_order+'f4').reshape((nweeks, emu.ny, emu.nx))

            print('*********************************************')
            print('Read variable recon2d from file')
            print(ff)
            print('')

            dum2d.fill(0)  # Reset dum2d
            for i in range(emu.nx):
                for j in range(emu.ny):
                    dum2d[j, i] = 1.0 - emupy.lib_var(recon_all - recon2d[:, j, i]) / var_all

            # Normalize by grid area and store in ev_space
            dum2d[ok_rac] /= emu.rac[ok_rac]
            ev_space[ic, :, :] = dum2d

        print('*********************************************')
        print('Finished computing explained variance (EV) as a function of')
        print('space and control with respect to the variance of full')
        print('reconstruction up to maximum lag.')
        print('   ev_space: EV per unit area')
        print('')

        print('Saving ev_space to file')
        print(ff_ev_space)
        print('')

        # Save ev_space to a file for future use
        if byte_order == '>':  # Big-endian
            ev_space_swapped = ev_space.byteswap()  # Swap bytes if necessary
            ev_space_swapped.tofile(ff_ev_space)
        else:
            ev_space.tofile(ff_ev_space)

    else:
        # Load ev_space from the file if it exists
        ev_space = np.fromfile(ff_ev_space, dtype=byte_order+'f4').reshape(nctrl, emu.ny, emu.nx)  

        print('*********************************************')
        print('Detected ev_space file. Reading explained variance (EV)')
        print('as a function of space and control with respect to')
        print('the variance of full reconstruction up to maximum lag.')
        print('   ev_space: EV per unit area')
        print('from file')
        print(ff_ev_space)
        print('')

    # -------------------------
    # Plot one explained variance map at a time.
    print('')
    print('Plot explained variance vs space (ev_space) ...')

    print()
    print('Choose control to plot ... ')
    for i in range(nctrl): 
        print(f"{i+1}) {fctrl[i]}")

    while True:
        print()
        ic = int(input(f'Enter control to plot explained variance (EV) vs space ...  (1-{nctrl})? '))
        if ic < 1 or ic > nctrl:
            break

        print('Control chosen:', fctrl[ic - 1])

        # Scale the data
        dum2d = np.zeros((emu.ny, emu.nx), dtype=np.float32)
        dum2d[:] = ev_space[ic - 1, :, :]
        dum = np.max(np.abs(dum2d))
        if dum != 0:
            order_of_magnitude = np.floor(np.log10(np.abs(dum)))
            dscale = 10.0 ** (-order_of_magnitude)
        else:
            dscale = 0.0

        dum2d *= dscale
        dumg = emupy.nat2globe(dum2d)

        # Mask dry grid points 
        masked_dumg = np.ma.masked_where(ref2d == 0, dumg)

        # Plot 
        plt.figure(figsize=(10,10))
        ftitle = f"{fctrl[ic -1]} EV per area (ev_space) scaled by x{dscale:.9e}"
        plt.title(ftitle)        
        plt.imshow(masked_dumg, origin='lower',cmap=cmap, aspect='auto')
        plt.colorbar()

        plt.ion()  # Enable interactive mode
        plt.show(block=False)  # Show the plot without blocking

    return ev_space
