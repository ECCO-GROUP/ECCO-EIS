pro ijloc, pert_x, pert_y, pert_i, pert_j
; Locate closest model grid point (i,j) to given lon/lat (x,y) 

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; Define the constants
d2r = !PI / 180.0

; Reference (x, y) to -180 to 180 East and -90 to 90 North
pert_x = pert_x mod 360.0
if pert_x gt 180.0 then pert_x = pert_x - 360.0
pert_y = pert_y mod 360.0
if pert_y gt 180.0 then pert_y = pert_y - 360.0
if pert_y gt 90.0 then pert_y = 180.0 - pert_y
if pert_y lt -90.0 then pert_y = -180.0 - pert_y

; Find (i, j) pair within 10 degrees of (x, y)
pert_i = -9
pert_j = -9
target = 9e9

for j = 0, ny-1 do begin
   for i = 0, nx-1 do begin
      if abs(yc[i, j] - pert_y) lt 10.0 then begin
         dumdist = sin(pert_y * d2r) * sin(yc[i, j] * d2r) + $
                   cos(pert_y * d2r) * cos(yc[i, j] * d2r) * cos((xc[i, j] - pert_x) * d2r)
         dumdist = acos(dumdist)
         if dumdist lt target then begin
            pert_i = i+1
            pert_j = j+1
            target = dumdist
         endif
      endif
   endfor
endfor
   
end

