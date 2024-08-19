function lib_index_g2n,xglb,yglb
; Return 
;   (xnat,ynat) index on native grid
; from
;   (xglb,yglb) index on lib_nat2globe.pro's global array. 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Template native array with no duplicate entries
native = findgen(nx,ny) + 1
lib_nat2globe,native,globe

; Values at (xglb,yglb)
iglobe = globe(xglb,yglb)
nn = n_elements(iglobe)
inat = lonarr(nn)
for i=0,nn-1 do inat(i) = where(native eq iglobe(i))

ij = array_indices(native, inat)

xnat = ij(0,*)
ynat = ij(1,*)

return, [xnat,ynat]
end

