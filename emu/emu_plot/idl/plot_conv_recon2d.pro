pro plot_conv_recon2d, frun, fctrl, recon1d_sum, ev_space
; Read Convolution Tool output recon2d_*.data

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; ---------------
print,'Reading recon2d_*.data and computing explained variance vs space (ev_space) ... '
print,''
print,'Variable recon2d is the adjoint gradient reconstruction (time-series) '
print,'as a function of space by a particular control using the maximum lag '
print,'chosen in the convolution. Here, recon2d is read to compute the explained'
print,'variance vs space (ev_space), but recon2d is not retained by this plotting'
print,'routine to minimize memory usage.'
print,''

; ---------------
; Get dimension

nctrl = n_elements(fctrl)

ss = size(recon1d_sum)
nweeks=ss(1)
nlag=ss(2)

; Set EMU output file directory
frun_output = frun + '/output/'

; ---------------
; Read recon2d 

recon2d = fltarr(nx,ny,nweeks)  ; Variable read from recon2d_*.data

ev_space = fltarr(nx,ny,nctrl) ; EV as a function of space for each control

recon_all = recon1d_sum(*,nlag-1) ; full reconstruction up to maximum lag 
var_all = lib_var(recon_all)      ; variance of recon_all

dum2d = fltarr(nx,ny)
ok_rac = where(rac ne 0)  ; index where grid area is zero 

; Check if ev_space has already been computed and saved.
ff_ev_space=frun_output + 'plot_conv_recon2d.ev_space'

if not file_test(ff_ev_space) then begin
; ff_ev_space does not yet exist

   for ic=0,nctrl-1 do begin 
      ff = frun_output + 'recon2d_' + fctrl(ic) + '.data'

      aa = file_search(ff,count=naa)
      if (naa ne 1) then begin
         print,'*********************************************'
         print,'No recon2d_'+fctrl(i)+'.data file found ... '
         print,''
         return
      endif
      
      close,1 & openr,1,ff,/swap_if_little_endian
      readu,1,recon2d

      print,'*********************************************'
      print,'Read variable recon2d from file '
      print,ff 
      print,''

      dum2d(*) = 0.
      for i=0,nx-1 do begin
         for j=0,ny-1 do begin
            dum2d(i,j) = 1. - lib_var(recon_all - recon2d(i,j,*))/var_all
         endfor
      endfor
      dum2d(ok_rac) = dum2d(ok_rac)/rac(ok_rac)
      ev_space(*,*,ic) = dum2d
   endfor

   print,'*********************************************'
   print,'Finished computing explained variance (EV) as a function of '
   print,'space and control with respect to the variance of full '
   print,'reconstruction up to maximum lag. '
   print,'   ev_space: EV per unit area '
   print,''

   print,'Saving ev_space to file '
   print,ff_ev_space
   print,''

   close,1 & openw,1,ff_ev_space,/swap_if_little_endian
   writeu,1,ev_space
   close,1

endif else begin 

; ff_ev_space exists
   close,1 & openr,1,ff_ev_space,/swap_if_little_endian
   readu,1,ev_space
   close,1

   print,'*********************************************'
   print,'Detected ev_space file. Reading explained variance (EV) '
   print,'as a function of space and control with respect to '
   print,'the variance of full reconstruction up to maximum lag. '
   print,'   ev_space: EV per unit area '
   print,'from file '
   print,ff_ev_space
   print,''

endelse

; -------------------------
; Plot one explained variance map at a time. 

print,''
print,'Plot explained variance vs space (ev_space) ...  '

lib_nat2globe,hfacc(*,*,0),dumg
landg = where(dumg eq 0, nlandg)  ; index where it is dry

print,''
print,'Choose control to plot ... '
for i=0,nctrl-1 do begin
   pdum=string(i+1,format='(i1)')+') '+fctrl(i)
   print,pdum
endfor

ic = 1
while (ic ge 1 and ic le nctrl) do begin 

   print,''
   print,'Enter control to plot explained variance (EV) vs space ...  (1-'+string(nctrl,format='(i0)')+')?'
   read, ic 
   if (ic lt 1 or ic gt nctrl) then break
   print,'Control chosen: ',fctrl(ic-1)

   ; scale 
   dum=max(abs(ev_space(*,*,ic-1)))
   if (dum ne 0) then begin
      order_of_magnitude=floor(alog10(abs(dum)))
      dscale = 10.^(-order_of_magnitude)
   endif else begin
      dscale = 0.
   endelse
   dum2d(*)=ev_space(*,*,ic-1)*dscale

   lib_nat2globe,dum2d,dumg
   dmin = min(dum2d)
   dmax = max(dum2d)
   dumg(landg) = 32767.
   lib_quickimage2,dumg,dmin,dmax,fctrl(ic-1)+' EV per area (ev_space) scaled by x'+string(dscale,format='(e9.0)')

endwhile

end
