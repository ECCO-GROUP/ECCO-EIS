pro plt_state3d, v3d, pinfo, ivar 
; Plot a particular depth of a 3d variable (v3d) scaled to O(1) 
; with mask corresponding to the variable (ivar)
;    ivar = 0 (THETA), 1 (SALT), 2 (U), 3 (V)
; with variable information (pinfo) printed as caption. 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Set arrays 
dum2d = fltarr(nx,ny)

; Loop among depths 
kdum = 1 
while (kdum ge 1 and kdum le nr) do begin 
   print,'Enter depth to plot ... (1-'+string(nr,format='(i0)')+')?'
   read, kdum
   kplot = kdum - 1 
   if (kplot lt 0 or kplot gt nr-1) then break 

   ; scale 
   dum=max(abs(v3d(*,*,kplot)))
   order_of_magnitude=floor(alog10(abs(dum)))
   dscale = 10.^(-order_of_magnitude)
   dum2d(*) = v3d(*,*,kplot) * dscale 

   ; Create land mask corresponding to variable (ivar) 
   if (ivar ne 2 and ivar ne 3) then begin ; T or S 
      lib_nat2globe,hfacc(*,*,kplot),dumg
      landg = where(dumg eq 0, nlandg)      ; index where it is dry
      oceang = where(dumg ne 0, noceang)    ; index where it is wet 
   endif else begin  
      if (ivar eq 3) then begin ; U
         lib_nat2globe,hfacw(*,*,kplot),dumg
         landg = where(dumg eq 0, nlandg)      ; index where it is dry
         oceang = where(dumg ne 0, noceang)    ; index where it is wet 
      endif else begin                         ; V 
         lib_nat2globe,hfacs(*,*,kplot),dumg
         landg = where(dumg eq 0, nlandg)      ; index where it is dry
         oceang = where(dumg ne 0, noceang)    ; index where it is wet 
      endelse
   endelse

   ; plot 
   lib_nat2globe,dum2d,dumg
   dmin = min(dumg(oceang))
   dmax = max(dumg(oceang))
   dumg(landg) = 32767.

   ftitle='k='+string(kdum,format='(i0)')+' ' + pinfo + ' scaled by x'+string(dscale,format='(e9.0)')
   lib_quickimage2,dumg,dmin,dmax,ftitle
endwhile

end

