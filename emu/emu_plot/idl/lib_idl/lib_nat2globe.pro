pro lib_nat2globe, llc, glb 
; Reorder native 90-by-1170 format array (llc) to a 
; geographically contiguious global 360-by-360 array (glb)
; for visualization. 

ss = size(llc)
nx = ss(1)

nx2 = nx*2
nx3 = nx*3
nx4 = nx*4
glb = fltarr(nx4,nx4)

; Face 1
glb(0:nx-1,0:nx3-1) = llc(*,0:nx3-1)

; Face 2 
ioff = nx
glb(nx:nx2-1,0:nx3-1) = llc(*,nx3:nx3*2-1)

; Face 3
glb(0:nx-1,nx3:*) = rotate(llc(*,2*nx3:2*nx3+nx-1),1)

; Face 4 
dum=fltarr(nx3,nx)
dum(*)=llc(*,2*nx3+nx:3*nx3+nx-1)
glb(nx2:nx3-1,0:nx3-1) = rotate(dum,3)

; Face 5
dum(*)=llc(*,3*nx3+nx:*)
glb(nx3:*,0:nx3-1) = rotate(dum,3)

end
