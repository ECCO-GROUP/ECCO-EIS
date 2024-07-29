FUNCTION lib_MAKEBAR, XSIZE, YSIZE, MINVAL, MAXVAL
;
;+
;NAME:
;	MAKEBAR
;
;PURPOSE:
;	Make a color bar.
;INPUT:
;	XSIZE  = X size
;	YSIZE  = Y size
;	MINVAL = minimum color value 
;	MAXVAL = maximum color value.
;	OPTIONS:
;		none.
;	OUTPUT:
;		The color bar.
;
;MODIFICATION HISTORY:
;	Written by Denis P. Leconte, Feb. 13, 1991
;-
;
res= fltarr(xsize, ysize)
for i= 0L, xsize - 1 do begin
  res(i, *)= float(i) / float(xsize - 1) * (maxval - minval) + minval
endfor
return, res
end
