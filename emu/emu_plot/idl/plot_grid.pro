pro plot_grid
; Tutorial of LLC grid

common emu_grid, nx, ny, nr, xc, yc, rc, dxc, dyc, drc, $
   xg, yg, dxg, dyg, rf, drf, hfacc, hfacw, hfacs, $
   cs, sn, rac, ras, raw, raz, dvol3d

; 
print,"The ECCO model (V4r4) uses the LLC90 grid (Lat-Lon-Cap) as its horizontal gridding system."
print,"Here, we briefly describe 1) how variables are defined on this grid and 2) how the variables"
print,"are stored in files. See https://ecco-group.org/user-guide-v4r4.htm for additional descriptions."
print," "

print,'Variables are defined on five "faces" that span the globe illustrated in the following plot'
print,"of the model's bathymetry (m). Press ENTER to display ..."
read 

bathy=fltarr(nx,ny)
for i=0,nx-1 do for j=0,ny-2 do for k=0,nr-1 do bathy(i,j)=bathy(i,j)+drf(k)*hfacc(i,j,k)
ng=where(bathy eq 0.,nng)
if (nng ne 0) then bathy(ng)=32767.

lib_plot_faces, bathy, 0, 6000., 'Bathymetry (m)'

end
