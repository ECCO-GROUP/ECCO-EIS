pro rd_state2d_r4, ff, ivar, fld2d
; Read a particular record (ivar) of a 2d file (ff) and return in fld2d 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Associate file unit with array 
data = assoc(1,fltarr(nx,ny))

; Read record in file 
close,1 & openr, 1, ff, /swap_if_little_endian
fld2d = data(ivar)
close,1

end

