# Read Sampling Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu

def plot_samp(frun):
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    ff = os.path.join(frun, 'output')
#    print(f"ff is {ff}") # debugging 

    # Read samp.out_? (OBJF time-series)
    fdum = 'samp.out_'
    fdum_all = fdum + '*'
    aa = glob.glob(os.path.join(ff, fdum_all))
    aa.sort()

#    print(f"Files matching {fdum_all}: {aa}")  # Debugging print

    if len(aa) != 1:
        print()
        if len(aa) == 0:
            print('*********************************************')
            print(f'File {fdum_all} not found ... ')
            print()
        else:
            print('*********************************************')
            print(f'More than one {fdum_all} found ... ')
            print()
        return

    ip = aa[0].find(fdum) + len(fdum)
    frec = aa[0][ip:]
    nrec = int(frec)

    smp = np.zeros(nrec, dtype=np.float32)
    smp_mn = 1.0

    with open(aa[0], 'rb') as f:
        smp = np.fromfile(f, dtype=byte_order+'f4', count=nrec)
        smp_mn = np.fromfile(f, dtype=byte_order+'f4', count=1)[0]

    emu.smp=smp
    emu.smp_mn=smp_mn

    print()
    print('*********************************************')
    print('Read variables')
    print('   smp: temporal anomaly of sampled variable')
    print('   smp_mn: reference time-mean of sampled variable')
    print(f'from file {aa[0]}')

#    # Print the first five elements of smp
#    print(f"The first five elements of smp are: {smp[:5]}")


    # Read samp.step_? (time-step)
    fdum = 'samp.step_' + frec
    aa = glob.glob(os.path.join(ff, fdum))
    aa.sort()

    if len(aa) == 0:
        print()
        print('*********************************************')
        print(f'File {fdum} not found ... ')
        print()
        return

    smp_hr = np.zeros(nrec, dtype=np.float32)

    with open(aa[0], 'rb') as f:
        smp_hr = np.fromfile(f, dtype=byte_order+'i4', count=nrec)

    emu.smp_hr=smp_hr

    print()
    print('*********************************************')
    print('Read variable')
    print('   smp_hr: sample time (hours from 1/1/1992 12Z)')
    print(f'from file {aa[0]}')

    smp_yday = (smp_hr /24.) / 365.0 + 1992.0

    # Plot
    print()
    print('Plotting sampled time-series ... ')

    samp_t = smp_yday
    samp_v = smp + smp_mn

    frun_file = os.path.basename(frun)

    tmin = int(np.floor(np.min(samp_t))) - 1
    tmax = int(np.ceil(np.max(samp_t))) + 1

    plt.figure()
    plt.plot(samp_t, samp_v, label='smp + smp_mn')
    plt.title(frun_file)
    plt.xlabel('smp_hr')
    plt.ylabel('smp + smp_mn')
    plt.xlim(tmin, tmax)
    plt.autoscale(axis='y')
    plt.grid(True)
    plt.legend()

    plt.ion()  # Enable interactive mode
    plt.show(block=False)  # Show the plot without blocking

