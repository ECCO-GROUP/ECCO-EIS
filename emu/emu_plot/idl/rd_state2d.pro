pro rd_state2d, ff, ivar, fvar, fgrd2d
; Read and plot a record of a state_2d_set1 file

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; 
n_ff = n_elements(ff)

idum = 1
ifile = 1
dum2d = fltarr(nx,ny)
fgrd2d = dum2d
data = assoc(1,dblarr(nx,ny))

lib_nat2globe,hfacc(*,*,0),dumg
landg = where(dumg eq 0, nlandg)  ; index where it is dry
oceang = where(dumg ne 0, noceang) ; index where it is wet 

idum = 1
while (idum ge 1 and idum le n_ff) do begin
   print,''
   print,'Enter file # to read ... (1-'+string(n_ff,format='(i0)')+')?'
   read, idum
   ifile=idum-1
   if (ifile lt 0 or ifile gt n_ff-1) then break
   
;   print,''
   print,'Reading file ... ',ff(ifile)

   close,1 & openr, 1, ff(ifile), /swap_if_little_endian

   fgrd2d(*) = float(data(ivar))
   dum2d(*) = fgrd2d(*)

   ; scale 
   dum=max(abs(dum2d))
   if (dum ne 0) then begin
      order_of_magnitude=floor(alog10(abs(dum)))
      dscale = 10.^(-order_of_magnitude)
   endif else begin
      dscale = 0.
   endelse
   dum2d(*)=dum2d(*)*dscale

   lib_nat2globe,dum2d,dumg
   dmin = min(dumg(oceang))
   dmax = max(dumg(oceang))
   dumg(landg) = 32767.

   fname=file_basename(ff(ifile))
   ftitle=fvar + string(idum,format='(1x,i0)') + ' ' + fname + ' scaled by x'+string(dscale,format='(e9.0)')
   lib_quickimage2,dumg,dmin,dmax,ftitle

endwhile

end

