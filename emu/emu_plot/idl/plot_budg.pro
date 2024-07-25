pro plot_budg, frun, emu_tend, emu_tend_name, emu_tint, emu_tint_name, budg_msk, budg_mkup, nmkup
; Read Budget Tool output

; ---------------
; Set EMU output file directory
frun_output = frun + '/output/'  

; Possible budget quantities
fbudg = ['volume', 'heat', 'salt', 'salinity', 'momentum']

; ---------------
; Read and sort global sum of converging fluxes (tendency) 
ff = frun_output + 'emu_budg.sum_tend'   ; tendency 
rd_budg_sum, ff, emubudg, emubudg_name, lhs, rhs, adv, mix, frc, nvar, ibud
emu_tend = emubudg
emu_tend_name = emubudg_name 
lhs_tend = lhs
rhs_tend = rhs 
adv_tend = adv
mix_tend = mix
frc_tend = frc 
print,'*********************************************'
print,'Read sum of ', fbudg(ibud), ' budget variables '
print,'   emu_tend: tendency time-series (per second)'
print,'   emu_tend_name: name of variables in emu_tend'
print,'from file ',ff
print,''

; ---------------
; Read and sort global sum of converging fluxes (time-integral) 
ff = frun_output + 'emu_budg.sum_tint'   ; time-integral 
rd_budg_sum, ff, emubudg, emubudg_name, lhs, rhs, adv, mix, frc, nvar, ibud
emu_tint = emubudg
emu_tint_name = emubudg_name 
lhs_tint = lhs
rhs_tint = rhs 
adv_tint = adv
mix_tint = mix
frc_tint = frc 
print,'*********************************************'
print,'Read sum of ', fbudg(ibud), ' budget variables '
print,'   emu_tint: time-intetrated tendency time-series'
print,'   emu_tint_name: name of variables in emu_tint'
print,'from file ',ff
print,''

nmonths = n_elements(lhs) 
tt = findgen(nmonths)/12.+1992.

; ------------------------------------------
; Read budget masks (for 3d converging fluxes on region boundary)
rd_budg_msk, frun_output, budg_msk 
      ; budg_msk : mask identifying location of budg_mkup read by rd_budg_mkup
print,'*********************************************'
print,'Read 3d masks emu_budg.msk3d_* that describe the spatial location'
print,'and direction (+/- 1) of the converging fluxes budg_mkup.'
print,'   budg_msk: structure variable of the 3d masks '
print,'      budg_msk(n).msk: name (location) of mask n '
print,'      budg_msk(n).msk_dim: dimension of mask n (n3d)'
print,'      *budg_msk(n).f_msk: weights (direction) of mask n '
print,'      *budg_msk(n).i_msk: i-index of mask n '
print,'      *budg_msk(n).j_msk: j-index of mask n '
print,'      *budg_msk(n).k_msk: k-index of mask n '
print,''

; ------------------------------------------
; Read budget makeup (3d field) 
rd_budg_mkup, frun_output, budg_msk, budg_mkup, nmkup 
      ; nmkup : # of terms in mkup 
      ; budg_mkup : converging flux as a function of space 
print,'*********************************************'
print,'Read converging fluxes from files emu_budg.mkup_* ' 
print,'(budget makeup) '
print,'   budg_mkup: structure variable of the fluxes '
print,'      budg_mkup(n).var: name of flux n '
print,'      budg_mkup(n).msk: name (location) of corresponding mask '
print,'      budg_mkup(n).isum: term in emu_budg.sum_tend that this flux (n) is summed in' 
print,'      budg_mkup(n).mkup_dim: spatial dimension of *budg_mkup(n).mkup '
print,'      *budg_mkup(n).mkup: flux time-series '
print,'   nmkup: number of different fluxes' 
print,''

; ------------------------------------------
; Plot

nplot = 2 + (nvar-2) + 3
npx = ceil(float(nplot)/2.)
!p.multi = [0,2,npx]

; ..........................
; LHS vs RHS read from emu_budg.sum_tend 
plot,tt,lhs_tend,title=fbudg(ibud)+' (tend): LHS, RHS, LHS-RHS (bk, rd, cy)';,thick=2
oplot,tt,rhs_tend,col=55
oplot,tt,lhs_tend-rhs_tend,col=22
lib_label,['lhs', 'rhs', 'lhs-rhs'],[1, 55, 22]

; LHS vs RHS read from emu_budg.sum_tint
plot,tt,lhs_tint,title=fbudg(ibud)+' (tint): LHS, RHS, LHS-RHS (bk, rd, cy)'
oplot,tt,rhs_tint,col=55
oplot,tt,lhs_tint-rhs_tint,col=22
lib_label,['lhs', 'rhs', 'lhs-rhs'],[1, 55, 22]

; ..........................
; emu_budg.sum_tend vs sum of emu_budg.mkup_*
; (Make sure 3d fluxes match the sum output, to confirm 3d fluxes are correct.) 

dum = fltarr(nmonths)
for isum = 2,nvar-1 do begin  ; Plot each term in emu_budg.sum except dt & lhs 
                              ; Check against sum of makeup.
   
   dum_ref = emu_tend(*,isum)
   plot,tt,dum_ref,title=fbudg(ibud)+' '+ emu_tend_name(isum) + ': sum, mkup, sum-mkup (bk,rd,cy)'
   lib_label,['sum', 'mkup', 'sum-mkup'],[1, 55, 22]

if (nmkup ne 0) then begin 
   imkup = where(budg_mkup.isum - 1 eq isum, mmkup)
;   print,'mmkup = ',mmkup
   dum(*)=0.
   for ik=0,mmkup-1 do for im=0,nmonths-1 do dum(im) = dum(im) + total( (*budg_mkup(imkup(ik)).mkup)(*,im) )
;   for ik=0,mmkup-1 do for im=0,nmonths-1 do dum(im) = dum(im) + total( double( (*budg_mkup(imkup(ik)).mkup)(*,im) ) )
   oplot,tt,dum,col=55
   oplot,tt,dum_ref-dum,col=22
endif 

endfor

; ..........................
; Examine budget makeup (different fluxes, not spatial location) 

; adv vs mix vs frc (tend)
dd = max(abs([lhs_tend,adv_tend,mix_tend,frc_tend]))
plot,tt,lhs_tend,title=fbudg(ibud)+' tend: lhs, adv, mix, frc (bk, rd, cy, gr)',yrange=[-dd,dd],ystyle=1
lib_label,['lhs', 'adv', 'mix', 'frc'],[1, 55, 22, 38]
oplot,tt,adv_tend,col=55
oplot,tt,mix_tend,col=22
oplot,tt,frc_tend,col=38

; adv vs mix vs frc (tint)
dd = max(abs([lhs_tint,adv_tint,mix_tint,frc_tint]))
plot,tt,lhs_tint,title=fbudg(ibud)+' tint: lhs, adv, mix, frc (bk, rd, cy, gr)',yrange=[-dd,dd],ystyle=1
lib_label,['lhs', 'adv', 'mix', 'frc'],[1, 55, 22, 38]
oplot,tt,adv_tint,col=55
oplot,tt,mix_tint,col=22
oplot,tt,frc_tint,col=38

; tint w/o trend
lib_mean_trend,tt,tcent,inva,a
lhs_tint_2 = lhs_tint - a#(inva#lhs_tint)
adv_tint_2 = adv_tint - a#(inva#adv_tint)
mix_tint_2 = mix_tint - a#(inva#mix_tint)
frc_tint_2 = frc_tint - a#(inva#frc_tint)

; adv vs mix vs frc (tint) w/o trend
dd = max(abs([lhs_tint_2,adv_tint_2,mix_tint_2,frc_tint_2]))
plot,tt,lhs_tint_2,title=fbudg(ibud)+' tint wo trend: lhs, adv, mix, frc (bk, rd, cy, gr)',yrange=[-dd,dd],ystyle=1
lib_label,['lhs', 'adv', 'mix', 'frc'],[1, 55, 22, 38]
oplot,tt,adv_tint_2,col=55
oplot,tt,mix_tint_2,col=22
oplot,tt,frc_tint_2,col=38

end
