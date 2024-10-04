# Read Attribution Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu

def plot_atrb(frun): 
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    ff = os.path.join(frun, 'output')

    # specify controls in file 
    fctrl = ['lhs', 'wind', 'htflx', 'fwflx', 'sflx', 'pload', 'ic']
    nterms=len(fctrl)

    emu.atrb_ctrl=fctrl

    # ---------------
    # Read atrb.out_? (OBJF time-series)

    fdum = 'atrb.out_'
    fdum_all = fdum + '*'
    aa = glob.glob(os.path.join(ff, fdum_all))
    aa.sort()

    if len(aa) != 1:
        print()
        if len(aa) == 0:
            print('*********************************************')
            print(f'File {fdum_all} not found ... ')
            print('')
        else:
            print('*********************************************')
            print(f'More than one {fdum_all} found ... ')
            print('')
        return

    ip = aa[0].find(fdum) + len(fdum)
    frec = aa[0][ip:]
    nrec = int(frec)  # Length of time-series

    atrb = np.zeros((nterms, nrec), dtype=np.float32)
    atrb_mn = np.zeros(nterms, dtype=np.float32)

# Fortran/IDL are column-major, Python is row-major
    with open(aa[0], 'rb') as f:
        atrb = np.fromfile(f, dtype=byte_order+'f4', count=nrec * nterms).reshape((nterms, nrec))
        atrb_mn = np.fromfile(f, dtype=byte_order+'f4', count=nterms)
 
    emu.atrb = atrb
    emu.atrb_mn = atrb_mn

    print('*********************************************')
    print('Read OBJF and contributions to it from different controls')
    print('   atrb: temporal anomaly ')
    print('   atrb_mn: reference time-mean ')
    print('   fctrl: names of atrb/atrb_mn variables ')
    print(f'from file {aa[0]}')
    print()

    # ---------------
    # Read atrb.step_? (time-step)

    fdum = 'atrb.step_' + frec
    aa = glob.glob(os.path.join(ff, fdum))
    aa.sort()

    if len(aa) == 0:
        print('*********************************************')
        print(f'File {fdum} not found ... ')
        print('')
        return

    atrb_hr = np.zeros(nrec, dtype=np.int32)

    with open(aa[0], 'rb') as f:
        atrb_hr = np.fromfile(f, dtype=byte_order+'i4', count=nrec)

    emu.atrb_hr = atrb_hr

    print('*********************************************')
    print('Read variable ')
    print('   atrb_hr: sample time (hours from 1/1/1992 12Z)')
    print(f'from file {aa[0]}')
    print('')

    atrb_t = (atrb_hr / 24.0) / 365.0 + 1992.0

    # Plot
    frun_file = os.path.basename(frun)

    tmin = int(np.floor(np.min(atrb_t))) - 1
    tmax = int(np.ceil(np.max(atrb_t))) + 1

    plt.figure()
    plt.plot(atrb_t, atrb[0, :], label=fctrl[0])
    for i in range(1, nterms):
        plt.plot(atrb_t, atrb[i, :], label=fctrl[i])

    plt.title(frun_file)
    plt.xlabel('atrb_hr')
    plt.ylabel('atrb')
    plt.xlim(tmin, tmax)
    plt.autoscale(axis='y')
    plt.grid(True)
    plt.legend()

    plt.ion()  # Enable interactive mode
    plt.show(block=False)  # Show the plot without blocking

#    print("**************** HELLO WORLD  from atrb *******************")
