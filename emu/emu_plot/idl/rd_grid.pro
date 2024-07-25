pro rd_grid, emu_ref ; reads in model grid information 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; ...............
; Spatial Dimension of model 
nx = 90
ny = 1170
nr = 50

; ...............
; Longitude of cell center (tracer grid)
ff = emu_ref + '/XC.data'
xc = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, xc
close, 1

; Latitude of cell center (tracer grid)
ff = emu_ref + '/YC.data'
yc = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, yc
close, 1

; Depth of cell center (tracer grid)
frc = emu_ref + '/RC.data'
rc = fltarr(nr) 
close, 1 & openr, 1, frc, /swap_if_little_endian
readu, 1, rc   ; center depth of layer
close, 1

; ...............

ff = emu_ref + '/DXC.data'
dxc = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, dxc
close, 1

ff = emu_ref + '/DYC.data'
dyc = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, dyc
close, 1

fdrf = emu_ref + '/DRC.data'
drc = fltarr(nr) 
close, 1 & openr, 1, fdrf, /swap_if_little_endian
readu, 1, drc  ; distance to level (or surface) above.
close, 1

; ...............

ff = emu_ref + '/XG.data'
xg = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, xg
close, 1

ff = emu_ref + '/YG.data'
yg = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, yg
close, 1

ff = emu_ref + '/DXG.data'
dxg = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, dxg
close, 1

ff = emu_ref + '/DYG.data'
dyg = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, dyg
close, 1

frf = emu_ref + '/RF.data'
rf = fltarr(nr+1) 
close, 1 & openr, 1, frf, /swap_if_little_endian
readu, 1, rf  ; depth of layer boundary
close, 1

fdrf = emu_ref + '/DRF.data'
drf = fltarr(nr) 
close, 1 & openr, 1, fdrf, /swap_if_little_endian
readu, 1, drf  ; layer thickness
close, 1

; ...............

fhfacc = emu_ref + '/hFacC.data'
hfacc = fltarr(nx,ny,nr) 
close, 1 & openr, 1, fhfacc, /swap_if_little_endian
readu, 1, hfacc
close, 1

fhfacw = emu_ref + '/hFacW.data'
hfacw = fltarr(nx,ny,nr) 
close, 1 & openr, 1, fhfacw, /swap_if_little_endian
readu, 1, hfacw
close, 1

fhfacs = emu_ref + '/hFacS.data'
hfacs = fltarr(nx,ny,nr) 
close, 1 & openr, 1, fhfacs, /swap_if_little_endian
readu, 1, hfacs
close, 1

; ...............

fcs = emu_ref + '/AngleCS.data'  ; cos(theta) where theta is angle of North measured clockwise from j
cs = fltarr(nx,ny) 
close, 1 & openr, 1, fcs, /swap_if_little_endian
readu, 1, cs
close, 1

fsn = emu_ref + '/AngleSN.data'  ; sin(theta)
sn = fltarr(nx,ny) 
close, 1 & openr, 1, fsn, /swap_if_little_endian
readu, 1, sn
close, 1

; ...............

; area
ff = emu_ref + '/RAC.data'
rac = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, rac
close, 1

ff = emu_ref + '/RAS.data'
ras = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, ras
close, 1

ff = emu_ref + '/RAW.data'
raw = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, raw
close, 1

ff = emu_ref + '/RAZ.data'
raz = fltarr(nx,ny)
close, 1 & openr, 1, ff, /swap_if_little_endian
readu, 1, raz
close, 1

; ...............
; volume

dvol3d = hfacc
for k=0,nr-1 do dvol3d(*,*,k) = dvol3d(*,*,k)*rac*drf(k)

end
