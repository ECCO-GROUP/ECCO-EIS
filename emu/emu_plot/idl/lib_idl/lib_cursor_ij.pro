pro lib_cursor_ij,glb,xg,yg,xn,yn  
; Get (i,j) index of a point chosen by clicking
; a plot of the nat2globe 2d image, glb, in both
; the native 90-by-1170 array and global 360-by-360 array. 
;   (xg,yg) index on global grid
;   (xn,yn) index on native grid
;
; .run ~/project/mitv4/idl/get_cursor2_v4.pro

mx = 90
my = 1170
native = findgen(90,1170) + 1
nat2globe,native,globe

cursor,xg,yg

xg = nint(xg)
yg = nint(yg)

; ----------------------------
inat = globe(xg,yg) - 1

if (inat ge 0) then begin 
    ij = index2ij(native,inat)
endif else begin
    ij = [-9,-9]
endelse

xn = ij(0)
yn = ij(1)

print,' (xg,yg, xn,yn) = ',xg,yg,'     ',xn,yn
return
end

