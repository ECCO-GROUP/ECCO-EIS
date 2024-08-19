pro plt_state2d, v2d, pinfo
; Plot 2d variable (v2d) scaled to O(1) 
; with variable information (pinfo) printed as caption. 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Set arrays
dum2d = fltarr(nx,ny)

lib_nat2globe,hfacc(*,*,0),dumg
landg = where(dumg eq 0, nlandg)  ; index where it is dry
oceang = where(dumg ne 0, noceang) ; index where it is wet 

; scale 
dum=max(abs(v2d))
if (dum ne 0) then begin
   order_of_magnitude=floor(alog10(abs(dum)))
   dscale = 10.^(-order_of_magnitude)
endif else begin
   dscale = 0.
endelse
dum2d(*)=v2d(*)*dscale

; Plot 
lib_nat2globe,dum2d,dumg
dmin = min(dumg(oceang))
dmax = max(dumg(oceang))
dumg(landg) = 32767.

ftitle=pinfo + ' scaled by x'+string(dscale,format='(e9.0)')
lib_quickimage2,dumg,dmin,dmax,ftitle

end

