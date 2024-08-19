# Read Budget Tool output

import os
import numpy as np
import glob
import matplotlib.pyplot as plt
import global_emu_var as emu
import lib_python as emupy
import plot_budg_sub 

def plot_budg(frun): 
    # Define the byte order ('>' for big-endian)
    byte_order = '>'

    # Set EMU output file directory
    frun_output = os.path.join(frun, 'output')

    # Possible budget quantities
    fbudg = ['volume', 'heat', 'salt', 'salinity', 'momentum']

    # ---------------
    # Read and sort global sum of converging fluxes (tendency) 
    ff = os.path.join(frun_output, 'emu_budg.sum_tend')   # tendency 
    emubudg_name, emubudg, lhs, rhs, adv, mix, frc, nvar, ibud, tt = plot_budg_sub.rd_budg_sum(ff) 

    # Assign the results to the appropriate variables
    emu_tend = emubudg
    emu_tend_name = emubudg_name 
    lhs_tend = lhs
    rhs_tend = rhs 
    adv_tend = adv
    mix_tend = mix
    frc_tend = frc 

    emu.budg_tend = emu_tend
    emu.budg_tend_name = emu_tend_name

    print('*********************************************')
    print(f'Read sum of {fbudg[ibud]} budget variables ')
    print('   budg_tend: tendency time-series (per second)')
    print('   budg_tend_name: name of variables in budg_tend')
    print(f'from file {ff}')
    print()

    # ---------------
    # Read and sort global sum of converging fluxes (time-integral)
    ff = os.path.join(frun_output, 'emu_budg.sum_tint')   # time-integral
    emubudg_name, emubudg, lhs, rhs, adv, mix, frc, nvar, ibud, tt = plot_budg_sub.rd_budg_sum(ff) 

    # Assign the results to the appropriate variables
    emu_tint = emubudg
    emu_tint_name = emubudg_name
    lhs_tint = lhs
    rhs_tint = rhs
    adv_tint = adv
    mix_tint = mix
    frc_tint = frc

    emu.budg_tint = emu_tint
    emu.budg_tint_name = emu_tint_name

    print('*********************************************')
    print(f'Read sum of {fbudg[ibud]} budget variables')
    print('   budg_tint: time-integrated tendency time-series')
    print('   budg_tint_name: name of variables in budg_tint')
    print(f'from file {ff}')
    print('')

    # Calculate number of months and create the time array
    nmonths = len(lhs_tint)
    tt = np.arange(nmonths) / 12.0 + 1992.0

    # ---------------
    # Read budget masks (for 3D converging fluxes on region boundary)
    budg_msk = plot_budg_sub.rd_budg_msk(frun_output)

    emu.budg_msk = budg_msk

    print('*********************************************')
    print('Read 3D masks emu_budg.msk3d_* that describe the spatial location')
    print('and direction (+/- 1) of the converging fluxes budg_mkup.')
    print('   budg_msk: list of dictionaries, each describing a 3D mask')
    print('      budg_msk[n]["msk"]: name (location) of mask n')
    print('      budg_msk[n]["msk_dim"]: dimension of mask n (n3D)')
    print('      budg_msk[n]["f_msk"]: weights (direction) of mask n')
    print('      budg_msk[n]["i_msk"]: i-index of mask n')
    print('      budg_msk[n]["j_msk"]: j-index of mask n')
    print('      budg_msk[n]["k_msk"]: k-index of mask n')
    print('The number of different masks (dictionaries) is len(budg_msk)')
    print('')

    # ---------------
    # Read budget makeup (3D field)
    budg_mkup, nmkup = plot_budg_sub.rd_budg_mkup(frun_output, budg_msk)

    emu.budg_mkup = budg_mkup
    emu.budg_nmkup = nmkup

    print('*********************************************')
    print('Read converging fluxes from files emu_budg.mkup_*')
    print('(budget makeup)')
    print('   budg_mkup: list of class objects, each describing a particular flux')
    print('      budg_mkup[n].var: name of flux n')
    print('      budg_mkup[n].msk: name (location) of corresponding mask')
    print('      budg_mkup[n].isum: term in emu_budg.sum_tend that this flux (n) is summed in')
    print('      budg_mkup[n].mkup_dim: spatial dimension of budg_mkup[n]["mkup"]')
    print('      budg_mkup[n].mkup: flux time-series')
    print('   budg_nmkup: number of different fluxes')
    print('               Same as len(budg_mkup)')
    print('')

    # debugging 
    #print('*********************************************')
    #for i, mkup in enumerate(budg_mkup):
    #    custom_attributes = [attr for attr in dir(mkup) if not attr.startswith('__')]
    #    print(f'Custom attributes of budg_mkup[{i}]: {custom_attributes}')
    #print('*********************************************')
    #print()
    # debugging 

    # ---------------
    # Plot 

    # Number of plots
    nplot = 2 + (nvar - 2) + 3
    npx = int(np.ceil(float(nplot) / 2.))
    fig, axes = plt.subplots(npx, 2, figsize=(10, npx * 5))
    axes = axes.flatten()

    # ..........................
    # LHS vs RHS read from emu_budg.sum_tend
    ip = 0
    ax = axes[ip]
    ax.plot(tt, lhs_tend, label='LHS', color='black', linewidth=2)
    ax.plot(tt, rhs_tend, label='RHS', color='red')
    ax.plot(tt, lhs_tend - rhs_tend, label='LHS-RHS', color='cyan')
    #ax.set_title(f'{fbudg[ibud]} (tend): LHS, RHS, LHS-RHS')
    # Place the title inside the plotting area using ax.text()
    ax.text(0.5, 0.9, f'{fbudg[ibud]} (tend)',
        transform=ax.transAxes, fontsize=12, verticalalignment='top',
        horizontalalignment='center')
    ax.legend()
    ip = ip + 1

    # LHS vs RHS read from emu_budg.sum_tint
    ax = axes[ip]
    ax.plot(tt, lhs_tint, label='LHS', color='black', linewidth=2)
    ax.plot(tt, rhs_tint, label='RHS', color='red')
    ax.plot(tt, lhs_tint - rhs_tint, label='LHS-RHS', color='cyan')
    #ax.set_title(f'{fbudg[ibud]} (tint): LHS, RHS, LHS-RHS')
    # Place the title inside the plotting area using ax.text()
    ax.text(0.5, 0.9, f'{fbudg[ibud]} (tint)',
        transform=ax.transAxes, fontsize=12, verticalalignment='top',
        horizontalalignment='center')
    ax.legend()
    ip = ip + 1

    # ..........................
    # emu_budg.sum_tend vs sum of emu_budg.mkup_*
    dum = np.zeros(nmonths)
    for idum in range(2, nvar):
        # Plot each term in emu_budg.sum except dt & lhs
        # Check against sum of makeup.
        dum_ref = emu_tend[idum, :]

        ax = axes[ip]  
        ax.plot(tt, dum_ref, label='sum', color='black')
        #ax.set_title(f'{fbudg[ibud]} {emu_tend_name[idum]}: sum, mkup, sum-mkup')
        # Place the title inside the plotting area using ax.text()
        ax.text(0.5, 0.9, f'{fbudg[ibud]} {emu_tend_name[idum]}',
                transform=ax.transAxes, fontsize=12, verticalalignment='top',
                horizontalalignment='center')

        if nmkup != 0:
            imkup = np.array([i for i, mkup in enumerate(budg_mkup) if mkup.isum - 1 == idum])

            if len(imkup) > 0:
                dum[:] = 0.
                for ik in imkup:
                    for im in range(nmonths):
                        dum[im] += np.sum(budg_mkup[ik].mkup[im, :])

                ax.plot(tt, dum, label='mkup', color='red')
                ax.plot(tt, dum_ref - dum, label='sum-mkup', color='cyan')
                ax.legend()
                ip = ip + 1

    # ..........................
    # Examine budget makeup (different fluxes, not spatial location) 

    # adv vs mix vs frc (tend)
    ax = axes[ip]
    dd = np.max(np.abs([lhs_tend, adv_tend, mix_tend, frc_tend]))
    ax.plot(tt, lhs_tend, label='lhs', color='black')
    ax.plot(tt, adv_tend, label='adv', color='red')
    ax.plot(tt, mix_tend, label='mix', color='cyan')
    ax.plot(tt, frc_tend, label='frc', color='green')
    #ax.set_title(f"{fbudg[ibud]} tend: lhs, adv, mix, frc")
    # Place the title inside the plotting area using ax.text()
    ax.text(0.5, 0.9, f'{fbudg[ibud]} tend',
            transform=ax.transAxes, fontsize=12, verticalalignment='top',
            horizontalalignment='center')
    ax.legend()
    ip = ip + 1

    # adv vs mix vs frc (tint)
    dd = np.max(np.abs([lhs_tint, adv_tint, mix_tint, frc_tint]))
    ax = axes[ip]
    ax.plot(tt, lhs_tint, label='lhs', color='black')
    ax.plot(tt, adv_tint, label='adv', color='red')
    ax.plot(tt, mix_tint, label='mix', color='cyan')
    ax.plot(tt, frc_tint, label='frc', color='green')
    #ax.set_title(f"{fbudg[ibud]} tint: lhs, adv, mix, frc")
    # Place the title inside the plotting area using ax.text()
    ax.text(0.5, 0.9, f'{fbudg[ibud]} tint',
            transform=ax.transAxes, fontsize=12, verticalalignment='top',
            horizontalalignment='center')
    ax.legend()
    ip = ip + 1

    # Tint without trend
    tcent, inva, a = emupy.lib_mean_trend(tt)  
    lhs_tint_2 = lhs_tint - np.dot(a, np.dot(inva, lhs_tint))
    adv_tint_2 = adv_tint - np.dot(a, np.dot(inva, adv_tint))
    mix_tint_2 = mix_tint - np.dot(a, np.dot(inva, mix_tint))
    frc_tint_2 = frc_tint - np.dot(a, np.dot(inva, frc_tint))

    # adv vs mix vs frc (tint) without trend
    dd = np.max(np.abs([lhs_tint_2, adv_tint_2, mix_tint_2, frc_tint_2]))
    ax = axes[ip]
    ax.plot(tt, lhs_tint_2, label='lhs', color='black')
    ax.plot(tt, adv_tint_2, label='adv', color='red')
    ax.plot(tt, mix_tint_2, label='mix', color='cyan')
    ax.plot(tt, frc_tint_2, label='frc', color='green')
    #ax.set_title(f"{fbudg[ibud]} tint wo trend: lhs, adv, mix, frc")
    # Place the title inside the plotting area using ax.text()
    ax.text(0.5, 0.9, f'{fbudg[ibud]} tint wo trend',
            transform=ax.transAxes, fontsize=12, verticalalignment='top',
            horizontalalignment='center')
    ax.legend()
    ip = ip + 1

    #plt.tight_layout()

    plt.ion()  # Enable interactive mode
    plt.show(block=False)  # Show the plot without blocking

