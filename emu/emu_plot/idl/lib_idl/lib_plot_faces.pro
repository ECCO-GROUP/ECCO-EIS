pro lib_plot_faces, llc, dmin, dmax, ftitle
; Plot compact varyable llc in tile format.

ss = size(llc)
nx = ss(1)

nx2 = nx*2
nx3 = nx*3
nx4 = nx*4
glb = fltarr(nx4,nx4)

; Face 1
face_1=fltarr(nx,nx3)
face_1 = llc(*,0:nx3-1)
lib_quickimage6,4,2,5, face_1, dmin, dmax, ftitle

; Face 2 
face_2=fltarr(nx,nx3)
face_2 = llc(*,nx3:nx3*2-1)
lib_quickimage6,4,2,6, face_2, dmin, dmax, ftitle

; Face 3
face_3=fltarr(nx,nx)
face_3 = rotate(llc(*,2*nx3:2*nx3+nx-1),1)
lib_quickimage6,4,4,6, face_3, dmin, dmax, ftitle

; Face 4 
face_4 = fltarr(nx3,nx)
face_4(*) = rotate(llc(*,2*nx3+nx:3*nx3+nx-1),3)
lib_quickimage6,2,4,4, face_4, dmin, dmax, ftitle

; Face 5
face_5 = fltarr(nx3,nx)
face_5(*) = rotate(llc(*,3*nx3+nx:*),3)
lib_quickimage6,2,4,2, face_5, dmin, dmax, ftitle

end
