pro lib_globe2nat, glb, llc 
; Reorder geographically contiguious global 360-by-360 array (glb)
; to native 90-by-1170 format array (llc). 
; Inverse of lib_nat2globe

ss = size(glb)
nx4 = ss(1)
nx = nx4/4

nx2 = nx*2
nx3 = nx*3

ny = nx*13 

llc = fltarr(nx,ny)

; Face 1
llc(*,0:nx3-1) = glb(0:nx-1,0:nx3-1) 

; Face 2 
ioff = nx
llc(*,nx3:nx3*2-1) = glb(nx:nx2-1,0:nx3-1) 

; Face 3
llc(*,2*nx3:2*nx3+nx-1) = rotate(glb(0:nx-1,nx3:*), 3)

; Face 4 
dum = rotate(glb(nx2:nx3-1,0:nx3-1),1)
llc(*,2*nx3+nx:3*nx3+nx-1) = dum

; Face 5
dum = rotate(glb(nx3:*,0:nx3-1),1)
llc(*,3*nx3+nx:*) = dum

end
