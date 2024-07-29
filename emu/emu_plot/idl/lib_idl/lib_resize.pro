FUNCTION lib_RESIZE, ARR, XRSIZ, YRSIZ
;
;+
; NAME:
;	RESIZE
; PURPOSE:
;	RESIZES a 2D array of DOUBLES by resampling it
; CATEGORY:
; CALLING SEQUENCE:
;	RESIZE, ARR, XRSIZ, YRSIZ 
; INPUTS:
;	ARR= The array
;	XZSIZ= X-dim of the resized array
;	YZSIZ= Y-dim of the resized array
; OPTIONAL INPUT PARAMETER:
;	None.
; OUTPUT:
;	Returns the resampled array
;
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	Bidimensional arrays of double precision floating point only.
; MODIFICATION HISTORY:
;	Written January 4, 1991 AD by Denis P. Leconte
;	February 13, 1991, Denis P. Leconte: 2-pass vector zoom
;-
;
s= size(arr)
xr= double(xrsiz-1) / double(s(1)-1)
yr= double(yrsiz-1) / double(s(2)-1)
res= fltarr(xrsiz, yrsiz)
res1= fltarr(s(1), yrsiz)
for j= 0L, yrsiz-1 do begin
  y= fix(double(j) / yr)
  res1(0:s(1)-1, j)= arr(*,y)
endfor
for i= 0L, xrsiz-1 do begin
  x= fix(double(i) / xr)
  res(i, *)= res1(x,*)
endfor
return, res
END
