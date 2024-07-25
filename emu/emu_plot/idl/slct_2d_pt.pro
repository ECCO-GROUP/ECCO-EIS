pro slct_2d_pt, pert_x, pert_y, pert_i, pert_j
; Select horizontal grid point

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; 

print,' '
print,'Choose horizontal location ... '
print,'Enter 1 to select native grid location (i,j),  '
print,'or 9 to select by longitude/latitude ... (1 or 9)? '
read, iloc

if (iloc ne 9) then begin 
   pert_i = 0
   pert_j = 0

   print,'Identify point in native grid ... '
   while (pert_i lt 1 or pert_i gt nx) do begin
      print,'i ... (1-',string(nx,format='(i0)')+') ?'
      read, pert_i
   endwhile
   while (pert_j lt 1 or pert_j gt ny) do begin
      print,'j ... (1-',string(ny,format='(i0)')+') ?'
      read, pert_j
   endwhile

   pert_x = xc(pert_i-1, pert_j-1)
   pert_y = yc(pert_i-1, pert_j-1)

endif else begin

; By long/lat   
   check_d = 0
   pert_x = 1.
   pert_y = 1. 
   print,'Enter location''s lon/lat (x,y) ... '
   
   while (check_d eq 0) do begin 
      print,'longitude ... (E)?'
      read, pert_x
      print,'latitude ... (N)?'
      read, pert_y

      ijloc, pert_x, pert_y, pert_i, pert_j

; Make sure point is wet      
      if (hfacc(pert_i,pert_j) eq 0.) then begin 
         fdum = 'Closest C-grid ('+string([pert_i,pert_j],format='(i2,1x,i4)')+') is dry.'
         print,fdum
         print,'Select another point ... '
      endif else begin 
         check_d = 1
      endelse
      
   endwhile 

endelse

; Confirm location
print,' ...... Chosen point is (i,j) = ',pert_i,pert_j
print,'C-grid is (long E, lat N) = ',xc(pert_i-1,pert_j-1),yc(pert_i-1,pert_j-1)
   
end

