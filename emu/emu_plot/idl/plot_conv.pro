pro plot_conv, frun, recon1d, istep, fctrl, ev_lag, ev_ctrl, ev_space
; Read Convolution Tool output

; ---------------
; Set EMU output file directory
frun_output = frun + '/output/'

; Get maximum lag from the name of the run (frun) 
; nlag is number of lags (max lag is nlag-1 weeks) 
ii = strpos(frun,'_',/reverse_search)
if (strlen(frun)-ii eq 7) then begin  ; frun has date & time at end
   ; Split the string by underscore '_'
   parts = STRSPLIT(frun, '_', /EXTRACT)
   ; Extract the third number from the end
   nlag = parts[parts.LENGTH - 3] + 1  ; lag starts from zero, so number of lag is +1
endif else begin ; frun does not have date & time at end 
   nlag = fix(strmid(frun,ii+1,strlen(frun)-ii)) + 1 ; lag starts from zero, so number of lag is +1
endelse

; specify controls in file 
fctrl = ['empmr', 'pload', 'qnet', 'qsw', 'saltflux', 'spflx', 'tauu', 'tauv']
nctrl = n_elements(fctrl)

; ---------------
; Read recon1d (Reconstruction time-series summed in space. Function
; of lag and control.)

nweeks = 1357 ; maximum number of weeks that should be in EMU Convolution Tool output

recon1d = fltarr(nweeks,nlag,nctrl)

dum = fltarr(nweeks,nlag)
recon1d_sum = fltarr(nweeks,nlag)  ; sum of all controls

for i=0,nctrl-1 do begin 
   ff = frun_output + 'recon1d_' + fctrl(i) + '.data'

   aa = file_search(ff,count=naa)
   if (naa ne 1) then begin
      print,'*********************************************'
      print,'No recon1d_'+fctrl(i)+'.data file found ... '
      print,''
      return
   endif
      
   close,1 & openr,1,ff,/swap_if_little_endian
   readu,1,dum
   recon1d(*,*,i) = dum
endfor

recon1d_sum(*,*) = recon1d(*,*,0)
for i=1,nctrl-1 do recon1d_sum(*,*) = recon1d_sum(*,*) + recon1d(*,*,i)

print,'*********************************************'
print,'Read variable recon1d, the global spatial sum time-series '
print,'of the convolution as a function of lag and control.' 
print,'   recon1d: adjoint gradient reconstruction'
print,'from file recon1d_*.data'
print,''

; ---------------
; Read istep (time-step; All istep files are identical) 

istep = lonarr(nweeks)

i = 0
   ff = frun_output + 'istep_' + fctrl(i) + '.data'

   aa = file_search(ff,count=naa)
   if (naa ne 1) then begin
      print,'*********************************************'
      print,'No istep_'+fctrl(i)+'.data file found ... '
      print,''
      return
   endif
      
   close,1 & openr,1,ff,/swap_if_little_endian
   readu,1,istep

ww = float(istep)/24./365. + 1992. 
wwmin = fix(min(ww))-1
wwmax = fix(max(ww))+1

print,'*********************************************'
print,'Read variable '
print,'   istep: time (hours since 1/1/1992 12Z) of recon1d '
print,'from file istep_empmr.data'
print,''

; -------------------------
; Compute Explained Variance vs lag (w/ all control)

vref = lib_var(recon1d_sum(*,nlag-1))
ev_lag = fltarr(nlag)
for i=0,nlag-1 do begin
   ev_lag(i) = 1. - lib_var(recon1d_sum(*,nlag-1) - recon1d_sum(*,i))/vref
endfor

tlag = findgen(nlag) ; start from zero lag 

print,'*********************************************'
print,'Computed Explained Variance (EV) vs lag with all controls. '
print,'   ev_lag: EV as function of lag'
print,''

; Explained Variance vs control (at max lag) 
recon_all=fltarr(nweeks)
recon_by_ctrl=fltarr(nweeks,nctrl)

recon_all(*) = recon1d_sum(*,nlag-1)
for ic=0,nctrl-1 do begin
   recon_by_ctrl(*,ic) = recon1d(*,nlag-1,ic)
endfor

vref = lib_var(recon_all)
ev_ctrl = fltarr(nctrl)
for ic=0,nctrl-1 do begin
   ev_ctrl(ic) = 1. - lib_var(recon_all - recon_by_ctrl(*,ic))/vref
endfor

print,'*********************************************'
print,'Computed Explained Variance (EV) vs control at maximum lag. '
print,'   ev_ctrl: EV as function of control'
print,''

tctrl = findgen(nctrl) + 1 
tctrl_min = min(tctrl)-1
tctrl_max = max(tctrl)+1

; -------------------------
; Plot

;!p.multi=[0,1,2]
cmin = 22
cmax = 55
cc=cmin + (cmax-cmin)*findgen(nctrl)/(nctrl-1)

ip=nlag-1 ; IDL counts from zero

while (ip ge 0 and ip le nlag-1) do begin 

; Plot reconstruction 
   !p.multi=[0,1,2]

   fdum = 'recon1d: reconstruction at lag='+string(ip,format='(i0)')

   plot,ww,recon1d_sum(*,ip),title=fdum,xrange=[wwmin,wwmax],xstyle=1
   for i=0,nctrl-1 do oplot,ww,recon1d(*,ip,i),col=cc(i)

; label 
   lib_label,['sum',fctrl],[1,cc]

; Plot Explained Variance
   !p.multi=[2,2,2]

   plot,tlag,ev_lag,title='Exp Var vs lag (ev_lag)',xtitle='lag(wks)',ytitle='Exp Var'
   oplot,[tlag(ip)],[ev_lag(ip)],psym=2,col=55,noclip=1,thick=2,symsize=2

   plot,tctrl,ev_ctrl,title='Exp Var vs ctrl (ev_ctrl) @ lag='+string(nlag-1,format='(i0)'),xtitle='controls', ytitle='Exp Var', $
        xticks=(nctrl-1), xtickv=tctrl, xtickname=fctrl, xrange=[tctrl_min,tctrl_max],xstyle=1
   for i=0,nctrl-1 do begin
      oplot,[tctrl(i)],[ev_ctrl(i)],psym=2,col=cc(i),thick=2,symsize=2
   endfor

   print,'Enter lag to plot ... (0-'+string(nlag-1,format='(i0)')+')?'
   read,ip 

endwhile

; ---------------
; Optionally read recon2d and compute explained variance as a function
; of space

rd_recon2d='no'
print,' '
print,'Read recon2d to compute explained variance vs space ... (y/n)?'
read, rd_recon2d

; Test for 'y' or 'Y'
do_recon2d = (STRPOS(rd_recon2d, 'y') ne -1) or (STRPOS(rd_recon2d, 'Y') ne -1)

; Output the result
ev_space = 'not computed'
if do_recon2d then begin
   plot_conv_recon2d, frun, fctrl, recon1d_sum, ev_space
endif

end
