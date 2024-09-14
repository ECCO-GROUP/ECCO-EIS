pro rd_ptracer, ff, ifile, trc
; Read and plot a record of a state_2d_set1 file

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Set variables 
n_ff = n_elements(ff)

dum2d = fltarr(nx,ny)
trc = fltarr(nx,ny,nr)

idum = 1
ifile = 1

; Create land mask 
lib_nat2globe,hfacc(*,*,0),dumg
landg = where(dumg eq 0, nlandg) ; index where it is dry

; Loop among files 
while (idum ge 1 and idum le n_ff) do begin
   print,''
   print,'Enter file # to read ... (1-'+string(n_ff,format='(i0)')+' or -1 to exit)?'
   read, idum
   ifile=idum-1
   if (ifile lt 0 or ifile gt n_ff-1) then break 
   
   print,''
   print,'Reading file ... ',ff(ifile)

   close,1 & openr, 1, ff(ifile), /swap_if_little_endian
   readu,1,trc

   dum2d(*) = 0.
   for k=0,nr-1 do begin
      dum2d(*) = dum2d(*) + trc(*,*,k)*drf(k)*hfacc(*,*,k)
   endfor

   dum2d_sum = total(dum2d*rac)

   fname=file_basename(ff(ifile))
   get_timestep,fname,'ptracer_mon',timestep

   print,''
   print,'time-step              = ',timestep
   print,'global volume integral = ',dum2d_sum
   
   ; scale 
   dum=max(abs(dum2d))
   order_of_magnitude=floor(alog10(abs(dum)))
   dscale = 10.^(-order_of_magnitude)
   dum2d(*) = dum2d*dscale

   ; plot 
   lib_nat2globe,dum2d,dumg
   dmin = min(dum2d)
   dmax = max(dum2d)
   dumg(landg) = 32767.

   ftitle=string(ifile+1,format='(1x,i0)') + ' ' + fname + ' scaled by x'+string(dscale,format='(e9.0)')
   lib_quickimage2,dumg,dmin,dmax,ftitle

endwhile

end

