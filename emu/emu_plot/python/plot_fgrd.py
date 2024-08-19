# Read Forward Gradient Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy

# Create a custom colormap that maps masked values to gray
cmap = plt.cm.jet
cmap.set_bad(color='gray')  # Set the color for masked elements to gray

def plot_fgrd(frun): 
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    ff = os.path.join(frun, 'output')


    # ---------------
    # Search available output

    print()
    print('Detected ')

    # Search for files matching the pattern
    fdum = 'state_2d_set1_day.*.data'
    aa_2d_day = glob.glob(os.path.join(ff, fdum))
    naa_2d_day = len(aa_2d_day)
    print(f"{naa_2d_day:6d} files of {fdum}")

    fdum = 'state_2d_set1_mon.*.data'
    aa_2d_mon = glob.glob(os.path.join(ff, fdum))
    naa_2d_mon = len(aa_2d_mon)
    print(f"{naa_2d_mon:6d} files of {fdum}")

    fdum = 'state_3d_set1_mon.*.data'
    aa_3d_mon = glob.glob(os.path.join(ff, fdum))
    naa_3d_mon = len(aa_3d_mon)
    print(f"{naa_3d_mon:6d} files of {fdum}")

    # ---------------
    # Define gradient variable to read and plot 
    f_var = ['SSH', 'OBP', 'THETA', 'SALT', 'U', 'V']
    nvar = len(f_var)

    # Prompt user to choose a variable
    print("\nChoose variable to plot ...")
    for i in range(nvar):
        pdum = f"{i+1}) {f_var[i]}"
        print(pdum)

    # Prompt user to select monthly or daily mean
    print("\nSelect monthly or daily mean ... (m/d)?")
    print("(NOTE: daily mean available for SSH and OBP only.)")
    fmd = input("Enter 'm' for monthly or 'd' for daily: ").strip().lower()

    # ---------------
    # Read and plot gradient of chosen variable 
    pvar = 0
    idum = 0

    if fmd == 'd':
        print("==> Reading and plotting daily means ...\n")
        while pvar < 1 or pvar > 2:
            pvar = int(input("Enter variable # to plot ... (1-2)? "))
            ivar = pvar - 1

        print(f"\nPlotting ... {f_var[ivar]}")

        # loop among daily mean 2d files 
        pfile = 1
        while pfile >= 1 and pfile <= naa_2d_day:
            print()
            pfile = int(input(f"Enter file # to read ... (1-{naa_2d_day})?"))
            if pfile < 1 or pfile > naa_2d_day:
                break
            ifile = pfile-1

            emu.fgrd2d = emupy.rd_state2d_r4(aa_2d_day[ifile], ivar)
            fname = os.path.basename(aa_2d_day[ifile])
            pinfo = f"{f_var[ivar]} {pfile} {fname}"
            emupy.plt_state2d(emu.fgrd2d, pinfo)

        print('*********************************************')
        print('Returning variable ')
        print('   fgrd2d: last plotted gradient (2d)')
        print()

    else:
        print("==> Reading and plotting monthly means ...\n")
        while pvar < 1 or pvar > nvar:
            pvar = int(input(f"Enter variable # to plot ... (1-{nvar})? "))
            ivar = pvar - 1

        print(f"\nPlotting ... {f_var[ivar]}")

        if ivar <= 1:

        # loop among monthly mean 2d files 
            pfile = 1
            while pfile >= 1 and pfile <= naa_2d_mon:
                print()
                pfile = int(input(f"Enter file # to read ... (1-{naa_2d_mon})?"))
                if pfile < 1 or pfile > naa_2d_mon:
                    break
                ifile = pfile-1
                
                emu.fgrd2d = emupy.rd_state2d_r4(aa_2d_mon[ifile], ivar)
                fname = os.path.basename(aa_2d_mon[ifile])
                pinfo = f"{f_var[ivar]} {pfile} {fname}"
                emupy.plt_state2d(emu.fgrd2d, pinfo)

            print('*********************************************')
            print('Returning variable ')
            print('   fgrd2d: last plotted gradient (2d)')
            print()

        else:

        # loop among monthly mean 3d files 
            pfile = 1
            while pfile >= 1 and pfile <= naa_3d_mon:
                print()
                pfile = int(input(f"Enter file # to read ... (1-{naa_3d_mon})?"))
                if pfile < 1 or pfile > naa_3d_mon:
                    break
                ifile = pfile-1

                emu.fgrd3d = emupy.rd_state3d(aa_3d_mon[ifile], ivar-2) # ivar-2 because no 3d SSH/OBP
                fname = os.path.basename(aa_3d_mon[ifile])
                pinfo = f"{f_var[ivar]} {pfile} {fname}"
                emupy.plt_state3d(emu.fgrd3d, pinfo, ivar-2) # ivar-2 because no 3d SSH/OBP

            print('*********************************************')
            print('Returning variable ')
            print('   fgrd3d: last plotted gradient (3d)')
            print()

