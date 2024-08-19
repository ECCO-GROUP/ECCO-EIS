pro rd_state3d, ff, ivar, fld3d
; Read a particular record (ivar) of a 3d file (ff) and return in fld3d 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Associate file unit with array 
data = assoc(1,fltarr(nx,ny,nr))

; Read record in file 
close,1 & openr, 1, ff, /swap_if_little_endian
fld3d = data(ivar)
close,1

end

