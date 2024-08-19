function lib_index_n2g,xnat,ynat
; Return 
;   (xglb,yglb) index on lib_nat2globe.pro's global array. 
; from
;   (xnat,ynat) index on native grid

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Template native array with no duplicate entries
native = findgen(nx,ny) + 1
lib_nat2globe,native,globe

; Values at (xnat,ynat)
inat = native(xnat,ynat)
nn = n_elements(inat)
iglobe = lonarr(nn)
for i=0,nn-1 do iglobe(i) = where(globe eq inat(i))

ij = array_indices(globe, iglobe)

xglb = ij(0,*)
yglb = ij(1,*)

return, [xglb,yglb]
end

 
