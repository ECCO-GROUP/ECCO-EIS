pro rd_state3d, ff, ivar, fvar, fgrd2d
; Read and plot a record of a state_2d_set1 file

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Set variables 
n_ff = n_elements(ff)

idum = 1
ifile = 1
dum2d = fltarr(nx,ny)
fgrd2d = dum2d
dum3d = fltarr(nx,ny,nr)
data = assoc(1,fltarr(nx,ny,nr))

ivar_infile = ivar - 2

; Loop among files 
while (ifile ge 1 and ifile le n_ff) do begin
   print,''
   print,'Enter file # to read ... (1-'+string(n_ff,format='(i0)')+')?'
   read, idum
   ifile=idum-1
   if (ifile lt 0 or ifile gt n_ff-1) then break 
   
;   print,''
   print,'Reading file ... ',ff(ifile)

   close,1 & openr, 1, ff(ifile), /swap_if_little_endian

   dum3d(*) = data(ivar_infile)

   kdum = 1 
   while (kdum ge 1 and kdum le nr) do begin 
;      print,''
      print,'Enter depth to plot ... (1-'+string(nr,format='(i0)')+')?'
      read, kdum
      kplot = kdum - 1 
      if (kplot lt 0 or kplot gt nr-1) then break 

   ; scale 
      dum=max(abs(dum3d(*,*,kplot)))
      order_of_magnitude=floor(alog10(abs(dum)))
      dscale = 10.^(-order_of_magnitude)
      fgrd2d(*) = dum3d(*,*,kplot)
      dum2d(*) = fgrd2d*dscale

   ; Create land mask 
      if (ivar ne 4 and ivar ne 5) then begin ; T or S 
         lib_nat2globe,hfacc(*,*,kplot),dumg
         landg = where(dumg eq 0, nlandg) ; index where it is dry
         oceang = where(dumg ne 0, noceang); index where it is wet 
      endif else begin  
         if (ivar eq 4) then begin ; U
            lib_nat2globe,hfacw(*,*,kplot),dumg
            landg = where(dumg eq 0, nlandg) ; index where it is dry
            oceang = where(dumg ne 0, noceang) ; index where it is wet 
         endif else begin                    ; V 
            lib_nat2globe,hfacs(*,*,kplot),dumg
            landg = where(dumg eq 0, nlandg) ; index where it is dry
            oceang = where(dumg ne 0, noceang) ; index where it is wet 
         endelse
      endelse

   ; plot 
      lib_nat2globe,dum2d,dumg
      dmin = min(dumg(oceang))
      dmax = max(dumg(oceang))
      dumg(landg) = 32767.

      fname=file_basename(ff(ifile))
      ftitle=fvar + ' k='+string(kdum,format='(i0)')+string(ifile+1,format='(1x,i0)') + ' ' + fname + ' scaled by x'+string(dscale,format='(e9.0)')
      lib_quickimage2,dumg,dmin,dmax,ftitle
   endwhile

endwhile

end

